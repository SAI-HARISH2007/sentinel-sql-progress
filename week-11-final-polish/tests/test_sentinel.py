"""
Sentinel — end-to-end tests for the finished project (weeks 1-10 loaded).

Run:   make test                (or)   pytest week-11-final-polish/tests -v
Needs: MySQL running with the full build loaded (scripts/build.sh 10) and:  pip install -r tests/requirements.txt

Connection settings come from the environment and default to the docker-compose.yml values:
    DB_HOST (127.0.0.1)  DB_PORT (3306)  DB_USER (root)  DB_PASS (sentinel_root_2026)  DB_NAME (sentinel)

Tests that write data run inside a transaction that is rolled back, so the database is left untouched
(except test_transfer_funds_*, which call a procedure that commits by design and restore the balances themselves).
"""
import os

import pytest

mysql = pytest.importorskip("mysql.connector")


def _connect(user=None, password=None):
    return mysql.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=user or os.getenv("DB_USER", "root"),
        password=password or os.getenv("DB_PASS", "sentinel_root_2026"),
        database=os.getenv("DB_NAME", "sentinel"),
        charset="utf8mb4",
        autocommit=False,
    )


@pytest.fixture()
def db():
    conn = _connect()
    yield conn
    conn.rollback()
    conn.close()


def rows(conn, sql, params=None):
    cur = conn.cursor(dictionary=True)
    cur.execute(sql, params or ())
    out = cur.fetchall()
    cur.close()
    return out


def scalar(conn, sql, params=None):
    r = rows(conn, sql, params)
    return list(r[0].values())[0] if r else None


def execute(conn, sql, params=None):
    cur = conn.cursor()
    try:
        cur.execute(sql, params or ())
        while True:                    # CALL transfer_funds returns a SELECT plus a status packet: read every result set
            if cur.with_rows:
                cur.fetchall()
            if not cur.nextset():
                break
    finally:
        cur.close()


# --------------------------------------------------------------------------- the five fraud personas (seeded in Week 4)

class TestPersonas:
    def reasons(self, db, txn_id):
        r = rows(db, "SELECT reasons, risk_score FROM alerts WHERE txn_id = %s", (txn_id,))
        assert r, f"transaction {txn_id} has no alert"
        return str(r[0]["reasons"]), float(r[0]["risk_score"])

    def test_traveller_impossible_travel(self, db):
        text, _ = self.reasons(db, 12042)          # Delhi 10:00 -> Chennai 10:10
        assert "Impossible travel" in text

    def test_night_owl_off_hours(self, db):
        text, _ = self.reasons(db, 12043)          # 02:30 for an account that shops 9-18
        assert "Off-hours" in text

    def test_burst_velocity(self, db):
        for txn_id in (12049, 12050, 12051):       # 6th, 7th and 8th payment inside five minutes
            text, _ = self.reasons(db, txn_id)
            assert "Velocity" in text

    def test_new_device_big_two_rules(self, db):
        text, score = self.reasons(db, 12052)      # 95,000 from a device the account never used
        assert "High amount" in text and "New device" in text
        assert score >= 2

    def test_bad_merchant_gets_merchant_risk_once_it_has_enough_alerts(self, db):
        flagged = scalar(db, "SELECT COUNT(*) FROM alerts WHERE txn_id BETWEEN 12053 AND 12067 AND reasons LIKE '%Merchant risk%'")
        assert flagged == 12                       # merchant 50 needs 3 alerts first, so 12053-12055 are not flagged for it

    def test_no_false_alarm_on_the_first_two_bad_merchant_rows_for_merchant_risk(self, db):
        for txn_id in (12053, 12054, 12055):
            text, _ = self.reasons(db, txn_id)
            assert "Merchant risk" not in text


# --------------------------------------------------------------------------- the trigger, live

class TestTrigger:
    def test_suspicious_insert_creates_alert_with_reasons(self, db):
        execute(db, """INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount, txn_time)
                       VALUES (1, 1, 999, 4, 95000.00, '2026-09-02 03:15:00')""")
        txn_id = scalar(db, "SELECT LAST_INSERT_ID()")
        r = rows(db, "SELECT risk_score, JSON_LENGTH(reasons) AS n FROM alerts WHERE txn_id = %s", (txn_id,))
        assert r and r[0]["n"] == 3 and float(r[0]["risk_score"]) == 3

    def test_ordinary_insert_creates_no_alert(self, db):
        execute(db, """INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount, txn_time)
                       SELECT 3, 5, device_id, 1, 800.00, '2026-09-04 13:00:00' FROM account_devices WHERE account_id = 3 LIMIT 1""")
        txn_id = scalar(db, "SELECT LAST_INSERT_ID()")
        assert scalar(db, "SELECT COUNT(*) FROM alerts WHERE txn_id = %s", (txn_id,)) == 0

    def test_disabled_rule_is_skipped(self, db):
        execute(db, "UPDATE rule_config SET enabled = FALSE WHERE rule_name = 'new_device'")
        execute(db, """INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount, txn_time)
                       VALUES (1, 1, 999, 4, 800.00, '2026-09-05 13:00:00')""")
        txn_id = scalar(db, "SELECT LAST_INSERT_ID()")
        text = scalar(db, "SELECT reasons FROM alerts WHERE txn_id = %s", (txn_id,)) or ""
        assert "New device" not in str(text)

    def test_status_change_is_audited_and_stamped(self, db):
        execute(db, """INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount, txn_time)
                       VALUES (1, 1, 999, 4, 95000.00, '2026-09-02 03:15:00')""")
        txn_id = scalar(db, "SELECT LAST_INSERT_ID()")
        alert_id = scalar(db, "SELECT alert_id FROM alerts WHERE txn_id = %s", (txn_id,))
        execute(db, "UPDATE alerts SET status = 'confirmed' WHERE alert_id = %s", (alert_id,))
        assert scalar(db, "SELECT reviewed_at IS NOT NULL FROM alerts WHERE alert_id = %s", (alert_id,)) == 1
        assert scalar(db, "SELECT COUNT(*) FROM audit_log WHERE table_name = 'alerts' AND record_id = %s", (alert_id,)) == 1

    def test_changing_a_threshold_changes_the_verdict(self, db):
        execute(db, """INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount, txn_time)
                       VALUES (1, 1, 999, 4, 95000.00, '2026-09-02 03:15:00')""")
        txn_id = scalar(db, "SELECT LAST_INSERT_ID()")
        assert "High amount" in str(scalar(db, "SELECT reasons FROM alerts WHERE txn_id = %s", (txn_id,)))
        execute(db, "UPDATE rule_config SET threshold_value = 50 WHERE rule_name = 'zscore'")
        execute(db, "CALL score_transaction(%s)", (txn_id,))
        assert "High amount" not in str(scalar(db, "SELECT reasons FROM alerts WHERE txn_id = %s", (txn_id,)))


# --------------------------------------------------------------------------- integrity

class TestConstraints:
    @pytest.mark.parametrize("sql", [
        "INSERT INTO users (full_name, email) VALUES (NULL, 'x@example.com')",                                     # NOT NULL
        "INSERT INTO users (full_name, email) VALUES ('Dup', 'user1@example.com')",                                # UNIQUE
        "INSERT INTO accounts (user_id) VALUES (99999999)",                                                         # FOREIGN KEY
        "INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount) VALUES (1,1,1,1,-5)",  # CHECK
        "DELETE FROM merchant_categories WHERE category_id = 1",                                                    # ON DELETE RESTRICT
    ])
    def test_bad_data_is_rejected(self, db, sql):
        with pytest.raises(mysql.Error):
            execute(db, sql)

    def test_cascade_delete(self, db):
        execute(db, "INSERT INTO users (user_id, full_name, email) VALUES (99001, 'Cascade', 'cascade@example.com')")
        execute(db, "INSERT INTO accounts (account_id, user_id) VALUES (99001, 99001)")
        execute(db, "DELETE FROM users WHERE user_id = 99001")
        assert scalar(db, "SELECT COUNT(*) FROM accounts WHERE account_id = 99001") == 0


# --------------------------------------------------------------------------- transactions

class TestTransferFunds:
    def balances(self, db):
        r = rows(db, "SELECT account_id, balance FROM accounts WHERE account_id IN (2, 3) ORDER BY account_id")
        return {x["account_id"]: x["balance"] for x in r}

    def test_transfer_moves_money_and_conserves_total(self, db):
        before = self.balances(db)
        execute(db, "CALL transfer_funds(2, 3, 1000.00, 64, 1)")
        db.commit()
        try:
            after = self.balances(db)
            assert after[2] == before[2] - 1000 and after[3] == before[3] + 1000
            assert sum(after.values()) == sum(before.values())
        finally:   # the procedure commits by design, so undo it explicitly
            execute(db, "DELETE FROM transactions WHERE account_id = 2 AND amount = 1000.00 AND txn_id > 12067")
            execute(db, "UPDATE accounts SET balance = %s WHERE account_id = 2", (before[2],))
            execute(db, "UPDATE accounts SET balance = %s WHERE account_id = 3", (before[3],))
            db.commit()

    @pytest.mark.parametrize("args", [
        "2, 3, 999999999.00, 64, 1",      # insufficient funds
        "2, 3, -50.00, 64, 1",            # negative amount
        "2, 2, 10.00, 64, 1",             # same account
        "2, 99999, 10.00, 64, 1",         # unknown account
    ])
    def test_bad_transfer_changes_nothing(self, db, args):
        before = self.balances(db)
        n_txn = scalar(db, "SELECT COUNT(*) FROM transactions")
        with pytest.raises(mysql.Error):
            execute(db, f"CALL transfer_funds({args})")
        db.rollback()
        assert self.balances(db) == before
        assert scalar(db, "SELECT COUNT(*) FROM transactions") == n_txn


# --------------------------------------------------------------------------- views and the function

class TestViewsAndFunction:
    def test_haversine_delhi_chennai(self, db):
        km = float(scalar(db, "SELECT haversine_km(28.7041, 77.1025, 13.0827, 80.2707)"))
        assert 1760 < km < 1775

    def test_every_rule_view_runs_and_personas_appear_in_the_combined_view(self, db):
        for v in ("rule_zscore", "rule_off_hours", "rule_new_device", "rule_velocity", "rule_impossible_travel", "rule_merchant_risk"):
            assert scalar(db, f"SELECT COUNT(*) FROM {v}") >= 0
        flagged = {r["txn_id"] for r in rows(db, "SELECT txn_id FROM v_transaction_risk WHERE txn_id BETWEEN 12041 AND 12067")}
        assert {12042, 12043, 12049, 12050, 12051, 12052}.issubset(flagged)

    def test_disabling_a_rule_empties_its_view(self, db):
        execute(db, "UPDATE rule_config SET enabled = FALSE WHERE rule_name = 'new_device'")
        assert scalar(db, "SELECT COUNT(*) FROM rule_new_device") == 0


# --------------------------------------------------------------------------- access control (needs Week 9 roles)

class TestRoles:
    def test_analyst_reads_views_but_not_tables(self):
        conn = _connect("analyst_user", "analyst_2026")
        try:
            assert scalar(conn, "SELECT COUNT(*) FROM v_daily_txn_summary") > 0
            with pytest.raises(mysql.Error):
                execute(conn, "SELECT COUNT(*) FROM transactions")
        finally:
            conn.close()

    def test_app_user_can_insert_but_not_read_users(self):
        conn = _connect("app_user", "app_2026")
        try:
            with pytest.raises(mysql.Error):
                execute(conn, "SELECT * FROM users LIMIT 1")
        finally:
            conn.close()
