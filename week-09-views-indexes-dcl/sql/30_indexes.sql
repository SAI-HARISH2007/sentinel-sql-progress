-- =============================================================================
-- Week 9 — INDEXES
-- 30_indexes.sql — speed up the access paths the rules actually use
-- =============================================================================
-- An index is a sorted copy of one or more columns (a B+ tree) that lets MySQL jump to matching rows instead of
-- reading the whole table. Cost: extra disk space, and every INSERT/UPDATE must maintain the index too.
-- Rule of thumb: index the columns you filter, join or sort by, in the order you use them.
--
-- Measure before and after: demo/explain_before_after.sql, results in docs/benchmark_measured.md.
--
-- Deliberately NOT created: an index on alerts(txn_id) or behaviour_baselines(account_id). Both columns are already
-- UNIQUE, and a UNIQUE constraint IS an index. A second one would only slow down writes.

USE sentinel;

-- transactions: almost every query filters by account (and then time) or by merchant
CREATE INDEX idx_txn_account_time  ON transactions (account_id, txn_time);   -- velocity, travel, baselines, per-account history
CREATE INDEX idx_txn_merchant_time ON transactions (merchant_id, txn_time);  -- merchant risk
CREATE INDEX idx_txn_location      ON transactions (location_id);
CREATE INDEX idx_txn_time          ON transactions (txn_time);               -- date-range reports

-- alerts: dashboards filter by status then sort by newest
CREATE INDEX idx_alert_status ON alerts (status, created_at);
CREATE INDEX idx_alert_rule   ON alerts (rule_name);

-- login_history and audit_log: lookups by account / table, newest first
CREATE INDEX idx_lh_account_time   ON login_history (account_id, login_time);
CREATE INDEX idx_audit_table_time  ON audit_log (table_name, changed_at);

-- account_devices: "which accounts use this device?" (the primary key covers the other direction)
CREATE INDEX idx_ad_device ON account_devices (device_id);
