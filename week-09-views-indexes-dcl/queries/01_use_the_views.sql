-- Week 9 — using the views. A view is queried like a table; you never see the SELECT behind it.
USE sentinel;

-- Each rule on its own
SELECT * FROM rule_zscore            ORDER BY z_score DESC LIMIT 5;
SELECT * FROM rule_off_hours;
SELECT * FROM rule_new_device        WHERE txn_id >= 12041 LIMIT 5;
SELECT * FROM rule_velocity;
SELECT * FROM rule_impossible_travel ORDER BY implied_speed_kmh DESC LIMIT 5;
SELECT * FROM rule_merchant_risk     LIMIT 5;       -- empty until Week 10 has created alerts

-- All rules together: the most suspicious transactions and WHY
SELECT txn_id, account_id, amount, risk_score, reasons
FROM v_transaction_risk
ORDER BY risk_score DESC, amount DESC
LIMIT 10;

-- How many transactions fire 1, 2, 3 ... rules?
SELECT risk_score, COUNT(*) AS txns FROM v_transaction_risk GROUP BY risk_score ORDER BY risk_score;

-- Tuning without touching any code: make Rule 1 stricter, look, put it back
UPDATE rule_config SET threshold_value = 5.0 WHERE rule_name = 'zscore';
SELECT COUNT(*) AS z_over_5 FROM rule_zscore;
UPDATE rule_config SET threshold_value = 3.0 WHERE rule_name = 'zscore';
SELECT COUNT(*) AS z_over_3 FROM rule_zscore;

-- Switch a rule OFF: the view empties itself
UPDATE rule_config SET enabled = FALSE WHERE rule_name = 'new_device';
SELECT COUNT(*) AS new_device_while_disabled FROM rule_new_device;       -- 0
UPDATE rule_config SET enabled = TRUE WHERE rule_name = 'new_device';
SELECT COUNT(*) AS new_device_while_enabled FROM rule_new_device;        -- 16

-- Reporting views
SELECT * FROM v_daily_txn_summary LIMIT 3;
SELECT * FROM v_top_risky_users LIMIT 3;       -- empty until alerts exist
