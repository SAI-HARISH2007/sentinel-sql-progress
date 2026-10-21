-- =============================================================================
-- Week 9 — VIEWS for reports: what an analyst or dashboard reads
-- 20_reporting_views.sql
-- =============================================================================
-- Joins several tables so a reader never needs to know the table layout (this is "logical data independence").
-- Because MySQL views run with their DEFINER's rights, a role can be given SELECT on a view without any right
-- to the tables underneath. 40_roles_dcl.sql relies on that.

USE sentinel;

-- Open alerts with full context. Empty until Week 10 creates alerts.
CREATE OR REPLACE VIEW v_active_alerts AS
SELECT al.alert_id,
       al.txn_id,
       al.rule_name,
       al.risk_score,
       al.reasons,
       al.status,
       al.created_at,
       t.amount,
       t.txn_time,
       a.account_id,
       u.full_name         AS user_name,
       u.email,
       m.merchant_name,
       mc.category_name    AS merchant_category,
       l.city              AS txn_city,
       d.device_type,
       d.os                AS device_os
FROM alerts al
JOIN transactions        t  ON t.txn_id        = al.txn_id
JOIN accounts            a  ON a.account_id    = t.account_id
JOIN users               u  ON u.user_id       = a.user_id
JOIN merchants           m  ON m.merchant_id   = t.merchant_id
JOIN merchant_categories mc ON mc.category_id  = m.category_id
JOIN locations           l  ON l.location_id   = t.location_id
JOIN devices             d  ON d.device_id     = t.device_id
WHERE al.status = 'open';

-- Accounts with the most alerts
CREATE OR REPLACE VIEW v_top_risky_users AS
SELECT a.account_id,
       u.full_name,
       u.email,
       COUNT(al.alert_id)            AS total_alerts,
       ROUND(AVG(al.risk_score), 2)  AS avg_risk_score,
       MAX(al.risk_score)            AS max_risk_score
FROM alerts al
JOIN transactions t ON t.txn_id     = al.txn_id
JOIN accounts     a ON a.account_id = t.account_id
JOIN users        u ON u.user_id    = a.user_id
GROUP BY a.account_id, u.full_name, u.email
ORDER BY total_alerts DESC, a.account_id
LIMIT 50;

-- Alerts per city per day
CREATE OR REPLACE VIEW v_alerts_by_city_day AS
SELECT l.city,
       DATE(t.txn_time)             AS txn_date,
       COUNT(*)                     AS alert_count,
       ROUND(AVG(al.risk_score), 2) AS avg_risk_score
FROM alerts al
JOIN transactions t ON t.txn_id      = al.txn_id
JOIN locations    l ON l.location_id = t.location_id
GROUP BY l.city, DATE(t.txn_time)
ORDER BY txn_date DESC, alert_count DESC;

-- Daily activity summary. Works from Week 4 on, because it needs no alerts.
CREATE OR REPLACE VIEW v_daily_txn_summary AS
SELECT DATE(txn_time)              AS txn_date,
       COUNT(*)                    AS total_txns,
       ROUND(SUM(amount), 2)       AS total_amount,
       ROUND(AVG(amount), 2)       AS avg_amount,
       MIN(amount)                 AS min_amount,
       MAX(amount)                 AS max_amount,
       COUNT(DISTINCT account_id)  AS unique_accounts
FROM transactions
GROUP BY DATE(txn_time)
ORDER BY txn_date DESC;
