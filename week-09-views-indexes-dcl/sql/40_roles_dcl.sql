-- =============================================================================
-- Week 9 — DCL: roles, GRANT, REVOKE   (principle of least privilege)
-- 40_roles_dcl.sql
-- =============================================================================
-- DCL = Data Control Language: who may do what. A ROLE is a named bundle of privileges; you GRANT the role to users.
--
--   fraud_analyst : read the report/rule views, and close alerts. NO access to the raw tables.
--   txn_app       : the payment application - may insert and read transactions, nothing else.
--   api_reader    : the read-only dashboard/API login - the report views and the rule thresholds, nothing else.
--   db_admin      : everything inside `sentinel`.
--
-- The passwords below are for a local teaching database only. Never commit real credentials.

USE sentinel;

CREATE ROLE IF NOT EXISTS 'fraud_analyst';
CREATE ROLE IF NOT EXISTS 'txn_app';
CREATE ROLE IF NOT EXISTS 'api_reader';
CREATE ROLE IF NOT EXISTS 'db_admin';

-- fraud_analyst: SELECT on views only ...
GRANT SELECT ON sentinel.v_active_alerts      TO 'fraud_analyst';
GRANT SELECT ON sentinel.v_top_risky_users    TO 'fraud_analyst';
GRANT SELECT ON sentinel.v_alerts_by_city_day TO 'fraud_analyst';
GRANT SELECT ON sentinel.v_daily_txn_summary  TO 'fraud_analyst';
GRANT SELECT ON sentinel.v_transaction_risk   TO 'fraud_analyst';
GRANT SELECT ON sentinel.rule_zscore            TO 'fraud_analyst';
GRANT SELECT ON sentinel.rule_off_hours         TO 'fraud_analyst';
GRANT SELECT ON sentinel.rule_new_device        TO 'fraud_analyst';
GRANT SELECT ON sentinel.rule_velocity          TO 'fraud_analyst';
GRANT SELECT ON sentinel.rule_impossible_travel TO 'fraud_analyst';
GRANT SELECT ON sentinel.rule_merchant_risk     TO 'fraud_analyst';
-- ... plus the right to CLOSE an alert. A column-level UPDATE grant is not enough on its own: MySQL also needs to be
-- allowed to READ the columns in the WHERE clause, so those get a column-level SELECT.
GRANT SELECT (alert_id, txn_id, status, reviewed_at) ON sentinel.alerts TO 'fraud_analyst';
GRANT UPDATE (status, reviewed_at)                   ON sentinel.alerts TO 'fraud_analyst';

-- txn_app: the application inserts transactions and can read them back
GRANT INSERT, SELECT ON sentinel.transactions TO 'txn_app';

-- api_reader: read-only; the four report views plus the thresholds. No raw tables, no writes.
GRANT SELECT ON sentinel.v_active_alerts      TO 'api_reader';
GRANT SELECT ON sentinel.v_daily_txn_summary  TO 'api_reader';
GRANT SELECT ON sentinel.v_top_risky_users    TO 'api_reader';
GRANT SELECT ON sentinel.v_alerts_by_city_day TO 'api_reader';
GRANT SELECT ON sentinel.rule_config          TO 'api_reader';

-- db_admin: everything in this database (but not other databases)
GRANT ALL PRIVILEGES ON sentinel.* TO 'db_admin';

-- Users, and which role each gets
CREATE USER IF NOT EXISTS 'analyst_user'@'%' IDENTIFIED BY 'analyst_2026';
CREATE USER IF NOT EXISTS 'app_user'@'%'     IDENTIFIED BY 'app_2026';
CREATE USER IF NOT EXISTS 'admin_user'@'%'   IDENTIFIED BY 'admin_2026';
CREATE USER IF NOT EXISTS 'api_user'@'%'     IDENTIFIED BY 'api_2026';

GRANT 'fraud_analyst' TO 'analyst_user'@'%';
GRANT 'txn_app'       TO 'app_user'@'%';
GRANT 'db_admin'      TO 'admin_user'@'%';
GRANT 'api_reader'    TO 'api_user'@'%';

-- A role only takes effect at login if it is a DEFAULT role
SET DEFAULT ROLE 'fraud_analyst' TO 'analyst_user'@'%';
SET DEFAULT ROLE 'txn_app'       TO 'app_user'@'%';
SET DEFAULT ROLE 'db_admin'      TO 'admin_user'@'%';
SET DEFAULT ROLE 'api_reader'    TO 'api_user'@'%';
