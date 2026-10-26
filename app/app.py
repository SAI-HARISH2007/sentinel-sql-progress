"""
Sentinel web app: a small CRUD front end over the finished database.

    pip install -r requirements.txt
    python3 app.py            then open http://127.0.0.1:5000

All the fraud logic stays in MySQL. This file only moves rows in and out.
Adding a transaction runs the same INSERT as the SQL scripts, so the AFTER INSERT
trigger scores it and, if a rule fires, writes the alert. The response shows that result.

Connection settings come from the environment (same names as the tests):
    DB_HOST (127.0.0.1)  DB_PORT (3306)  DB_USER (root)  DB_PASS (sentinel_root_2026)  DB_NAME (sentinel)
"""
import os
import json
import decimal
import datetime

import mysql.connector
from mysql.connector import errors
from flask import Flask, jsonify, request, send_from_directory

app = Flask(__name__, static_folder="static", static_url_path="/static")


def connect():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASS", "sentinel_root_2026"),
        database=os.getenv("DB_NAME", "sentinel"),
        charset="utf8mb4",
        autocommit=True,
    )


def clean(v):
    if isinstance(v, decimal.Decimal):
        return float(v)
    if isinstance(v, (datetime.datetime, datetime.date)):
        return v.isoformat(sep=" ") if isinstance(v, datetime.datetime) else v.isoformat()
    if isinstance(v, (bytes, bytearray)):
        return v.decode("utf8", "replace")
    return v


def query(sql, params=(), one=False):
    conn = connect()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(sql, params)
        rows = [{k: clean(v) for k, v in r.items()} for r in cur.fetchall()]
        cur.close()
        return (rows[0] if rows else None) if one else rows
    finally:
        conn.close()


def execute(sql, params=()):
    """Run one write. Returns (last insert id, rows affected)."""
    conn = connect()
    try:
        cur = conn.cursor()
        cur.execute(sql, params)
        out = (cur.lastrowid, cur.rowcount)
        cur.close()
        return out
    finally:
        conn.close()


@app.errorhandler(errors.Error)
def db_error(e):
    msg = e.msg if getattr(e, "msg", None) else str(e)
    code = getattr(e, "errno", 0)
    if code == 1451:
        msg = "Cannot delete: other rows still depend on this one (foreign key RESTRICT)."
    elif code == 1452:
        msg = "That reference does not exist (foreign key check failed)."
    elif code == 1062:
        msg = "Duplicate value: " + msg
    elif code == 3819:
        msg = "A CHECK constraint rejected the value (for example amount must be above 0)."
    return jsonify(error=msg), 400


# --------------------------------------------------------------------------
# Generic CRUD entities. Only the columns listed in "cols" can be written.
# --------------------------------------------------------------------------
ENT = {
    "users": dict(
        table="users", pk="user_id", cols=["full_name", "email", "phone", "date_of_birth"],
        select="SELECT user_id, full_name, email, phone, date_of_birth, created_at FROM users",
        search="full_name, email, phone", order="user_id DESC"),
    "accounts": dict(
        table="accounts", pk="account_id", cols=["user_id", "account_type", "balance", "status"],
        select="SELECT a.account_id, a.user_id, u.full_name AS owner, a.account_type, a.balance, a.status, a.created_at "
               "FROM accounts a JOIN users u ON u.user_id = a.user_id",
        search="u.full_name, a.account_type, a.status", order="a.account_id DESC", alias="a"),
    "merchants": dict(
        table="merchants", pk="merchant_id",
        cols=["merchant_name", "category_id", "city", "latitude", "longitude", "risk_score"],
        select="SELECT m.merchant_id, m.merchant_name, m.category_id, c.category_name, m.city, m.latitude, m.longitude, m.risk_score "
               "FROM merchants m JOIN merchant_categories c ON c.category_id = m.category_id",
        search="m.merchant_name, c.category_name, m.city", order="m.merchant_id DESC", alias="m"),
    "devices": dict(
        table="devices", pk="device_id", cols=["device_type", "os", "browser", "fingerprint_hash"],
        select="SELECT device_id, device_type, os, browser, fingerprint_hash FROM devices",
        search="device_type, os, browser", order="device_id DESC"),
    "locations": dict(
        table="locations", pk="location_id", cols=["city", "state", "country", "latitude", "longitude"],
        select="SELECT location_id, city, state, country, latitude, longitude FROM locations",
        search="city, state, country", order="location_id DESC"),
    "transactions": dict(
        table="transactions", pk="txn_id",
        cols=["account_id", "merchant_id", "device_id", "location_id", "amount", "txn_time", "status"],
        select="SELECT t.txn_id, t.account_id, t.merchant_id, t.device_id, t.location_id, u.full_name AS owner, m.merchant_name, d.device_type, l.city, "
               "t.amount, t.txn_time, t.status, al.alert_id, al.risk_score "
               "FROM transactions t JOIN accounts a ON a.account_id = t.account_id "
               "JOIN users u ON u.user_id = a.user_id JOIN merchants m ON m.merchant_id = t.merchant_id "
               "JOIN devices d ON d.device_id = t.device_id JOIN locations l ON l.location_id = t.location_id "
               "LEFT JOIN alerts al ON al.txn_id = t.txn_id",
        search="u.full_name, m.merchant_name, l.city, t.status", order="t.txn_id DESC", alias="t"),
    "alerts": dict(
        table="alerts", pk="alert_id", cols=["status"],
        select="SELECT al.alert_id, al.txn_id, u.full_name AS owner, m.merchant_name, l.city, t.amount, t.txn_time, "
               "al.risk_score, al.reasons, al.status, al.created_at, al.reviewed_at "
               "FROM alerts al JOIN transactions t ON t.txn_id = al.txn_id "
               "JOIN accounts a ON a.account_id = t.account_id JOIN users u ON u.user_id = a.user_id "
               "JOIN merchants m ON m.merchant_id = t.merchant_id JOIN locations l ON l.location_id = t.location_id",
        search="u.full_name, m.merchant_name, l.city, al.status, CAST(al.reasons AS CHAR)",
        order="al.alert_id DESC", alias="al"),
    "rules": dict(
        table="rule_config", pk="rule_id", cols=["enabled", "threshold_value"],
        select="SELECT rule_id, rule_name, enabled, threshold_value, "
               "JSON_UNQUOTE(JSON_EXTRACT(parameters_json, '$.description')) AS description, updated_at FROM rule_config",
        search="rule_name", order="rule_id", no_create=True, no_delete=True),
}


def pick(ent, body):
    return {c: (None if body.get(c) in ("", None) else body.get(c)) for c in ent["cols"] if c in body}


@app.get("/")
def index():
    return send_from_directory("static", "index.html")


@app.get("/api/<name>")
def list_rows(name):
    ent = ENT.get(name)
    if not ent:
        return jsonify(error="unknown"), 404
    q = request.args.get("q", "").strip()
    page = max(int(request.args.get("page", 1)), 1)
    size = 25
    where, params = "", []
    if q:
        where = f" WHERE CONCAT_WS(' ', {ent['search']}) LIKE %s"
        params.append(f"%{q}%")
    fl = request.args.get("status")
    if fl and name in ("alerts", "transactions", "accounts"):
        col = {"alerts": "al.status", "transactions": "t.status", "accounts": "a.status"}[name]
        where += (" AND " if where else " WHERE ") + col + " = %s"
        params.append(fl)
    if request.args.get("flagged") == "1" and name == "transactions":
        where += (" AND " if where else " WHERE ") + "al.alert_id IS NOT NULL"
    base = ent["select"]
    count_sql = "SELECT COUNT(*) AS n FROM (" + base + where + ") x"
    total = query(count_sql, params, one=True)["n"]
    rows = query(base + where + f" ORDER BY {ent['order']} LIMIT {size} OFFSET {(page - 1) * size}", params)
    if name == "alerts":
        for r in rows:
            try:
                r["reasons"] = json.loads(r["reasons"]) if r["reasons"] else []
            except (TypeError, ValueError):
                pass
    return jsonify(rows=rows, total=total, page=page, size=size)


@app.post("/api/<name>")
def create_row(name):
    ent = ENT.get(name)
    if not ent or ent.get("no_create") or name == "alerts":
        return jsonify(error="not allowed"), 405
    data = pick(ent, request.get_json(force=True))
    if name == "transactions" and not data.get("txn_time"):
        data.pop("txn_time", None)
    cols = ", ".join(data)
    marks = ", ".join(["%s"] * len(data))
    new_id, _ = execute(f"INSERT INTO {ent['table']} ({cols}) VALUES ({marks})", list(data.values()))
    out = {"id": new_id}
    if name == "transactions":
        # The AFTER INSERT trigger has already run. Read what it decided.
        out["alert"] = alert_for(new_id)
    return jsonify(out), 201


def alert_for(txn_id):
    a = query("SELECT alert_id, risk_score, reasons, status FROM alerts WHERE txn_id = %s", (txn_id,), one=True)
    if a and a["reasons"]:
        a["reasons"] = json.loads(a["reasons"])
    return a


@app.put("/api/<name>/<int:rid>")
def update_row(name, rid):
    ent = ENT.get(name)
    if not ent:
        return jsonify(error="unknown"), 404
    data = pick(ent, request.get_json(force=True))
    if not data:
        return jsonify(error="nothing to update"), 400
    sets = ", ".join(f"{c} = %s" for c in data)
    execute(f"UPDATE {ent['table']} SET {sets} WHERE {ent['pk']} = %s", list(data.values()) + [rid])
    out = {"ok": True}
    if name == "transactions":
        out["alert"] = alert_for(rid)
    return jsonify(out)


@app.delete("/api/<name>/<int:rid>")
def delete_row(name, rid):
    ent = ENT.get(name)
    if not ent or ent.get("no_delete"):
        return jsonify(error="not allowed"), 405
    execute(f"DELETE FROM {ent['table']} WHERE {ent['pk']} = %s", (rid,))
    return jsonify(ok=True)


# --------------------------------------------------------------------------
# Lookups for drop-downs, dashboard, audit log
# --------------------------------------------------------------------------
@app.get("/api/lookup/<name>")
def lookup(name):
    sql = {
        "users": "SELECT user_id AS id, full_name AS label FROM users ORDER BY full_name",
        "accounts": "SELECT a.account_id AS id, CONCAT('#', a.account_id, '  ', u.full_name, ' (', a.account_type, ')') AS label "
                    "FROM accounts a JOIN users u ON u.user_id = a.user_id WHERE a.status = 'active' ORDER BY u.full_name",
        "merchants": "SELECT merchant_id AS id, CONCAT(merchant_name, ' (', city, ')') AS label FROM merchants ORDER BY merchant_name",
        "categories": "SELECT category_id AS id, category_name AS label FROM merchant_categories ORDER BY category_name",
        "devices": "SELECT device_id AS id, CONCAT('#', device_id, '  ', device_type, ', ', COALESCE(os, '?')) AS label FROM devices ORDER BY device_id",
        "locations": "SELECT location_id AS id, CONCAT(city, ', ', COALESCE(state, '')) AS label FROM locations ORDER BY city",
    }.get(name)
    if not sql:
        return jsonify(error="unknown"), 404
    return jsonify(query(sql))


@app.get("/api/dashboard")
def dashboard():
    counts = query(
        "SELECT (SELECT COUNT(*) FROM transactions) AS transactions, (SELECT COUNT(*) FROM users) AS users, "
        "(SELECT COUNT(*) FROM accounts) AS accounts, (SELECT COUNT(*) FROM alerts) AS alerts, "
        "(SELECT COUNT(*) FROM alerts WHERE status = 'open') AS open_alerts", one=True)
    by_status = query("SELECT status AS label, COUNT(*) AS n FROM alerts GROUP BY status")
    by_reason = query(
        "SELECT SUBSTRING_INDEX(j.r, ' (', 1) AS label, COUNT(*) AS n FROM alerts, "
        "JSON_TABLE(alerts.reasons, '$[*]' COLUMNS (r VARCHAR(200) PATH '$')) j GROUP BY label ORDER BY n DESC")
    by_score = query("SELECT CAST(risk_score AS UNSIGNED) AS label, COUNT(*) AS n FROM alerts GROUP BY label ORDER BY label")
    daily = query("SELECT txn_date AS label, total_txns AS n FROM v_daily_txn_summary ORDER BY txn_date DESC LIMIT 14")
    daily.reverse()
    risky = query("SELECT full_name, total_alerts, max_risk_score FROM v_top_risky_users ORDER BY total_alerts DESC LIMIT 5")
    return jsonify(counts=counts, by_status=by_status, by_reason=by_reason, by_score=by_score, daily=daily, risky=risky)


@app.get("/api/audit")
def audit():
    return jsonify(rows=query(
        "SELECT audit_id, table_name, record_id, action, old_value_json, new_value_json, changed_by, changed_at "
        "FROM audit_log ORDER BY audit_id DESC LIMIT 100"))


if __name__ == "__main__":
    app.run(host=os.getenv("HOST", "127.0.0.1"), port=int(os.getenv("PORT", "5000")), debug=False)
