-- Week 10 — reading what the trigger and procedures produced
USE sentinel;

-- The five fraud personas, as the database now sees them
SELECT a.alert_id, a.txn_id, t.account_id, a.risk_score, a.reasons
FROM alerts a JOIN transactions t ON t.txn_id = a.txn_id
ORDER BY a.risk_score DESC, a.txn_id
LIMIT 10;

-- Which rules fire most? alerts.reasons is a JSON array of strings; JSON_SEARCH / LIKE on its text finds a rule.
SELECT 'High amount'       AS rule_name, COUNT(*) AS alerts FROM alerts WHERE reasons LIKE '%High amount%'
UNION ALL SELECT 'Off-hours',          COUNT(*) FROM alerts WHERE reasons LIKE '%Off-hours%'
UNION ALL SELECT 'New device',         COUNT(*) FROM alerts WHERE reasons LIKE '%New device%'
UNION ALL SELECT 'Velocity spike',     COUNT(*) FROM alerts WHERE reasons LIKE '%Velocity%'
UNION ALL SELECT 'Impossible travel',  COUNT(*) FROM alerts WHERE reasons LIKE '%Impossible travel%'
UNION ALL SELECT 'Merchant risk',      COUNT(*) FROM alerts WHERE reasons LIKE '%Merchant risk%';

-- JSON functions on the reasons column
SELECT txn_id, JSON_LENGTH(reasons) AS how_many_reasons, JSON_UNQUOTE(JSON_EXTRACT(reasons, '$[0]')) AS first_reason
FROM alerts ORDER BY txn_id LIMIT 5;

-- The reporting views from Week 9 now have data
SELECT * FROM v_top_risky_users LIMIT 5;
SELECT * FROM v_alerts_by_city_day LIMIT 5;
SELECT alert_id, user_name, amount, txn_city, risk_score FROM v_active_alerts ORDER BY risk_score DESC, alert_id LIMIT 5;

-- Rule 6 now has evidence to work with
SELECT merchant_id, merchant_name, MAX(alert_count) AS alerts, MAX(total_txns) AS txns, MAX(risk_multiplier) AS times_platform_rate
FROM rule_merchant_risk GROUP BY merchant_id, merchant_name;

-- Everything that changed alert status is in audit_log
SELECT audit_id, table_name, record_id, old_value_json, new_value_json, changed_by, changed_at FROM audit_log ORDER BY audit_id DESC LIMIT 5;

-- The nightly job
SELECT event_name, status, interval_value, interval_field, starts FROM information_schema.events WHERE event_schema = 'sentinel';
