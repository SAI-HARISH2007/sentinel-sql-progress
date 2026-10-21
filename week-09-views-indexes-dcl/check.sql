-- Week 9 assertions. Every row must say PASS.
-- (Written so they stay true after Week 10 adds alerts, procedures and triggers.)
USE sentinel;

SELECT '11 views exist (6 rules + combined + 4 reports)',
       IF((SELECT COUNT(*) FROM information_schema.views WHERE table_schema='sentinel') = 11, 'PASS', 'FAIL');

SELECT 'rule_zscore flags 145 transactions',          IF((SELECT COUNT(*) FROM rule_zscore)            = 145, 'PASS', 'FAIL');
SELECT 'rule_off_hours flags 2 (12030 and 12043)',    IF((SELECT GROUP_CONCAT(txn_id ORDER BY txn_id) FROM rule_off_hours) = '12030,12043', 'PASS', 'FAIL');
SELECT 'rule_new_device flags 16',                    IF((SELECT COUNT(*) FROM rule_new_device)        = 16,  'PASS', 'FAIL');
SELECT 'rule_velocity flags 12049, 12050, 12051',     IF((SELECT GROUP_CONCAT(txn_id ORDER BY txn_id) FROM rule_velocity) = '12049,12050,12051', 'PASS', 'FAIL');
SELECT 'rule_impossible_travel flags 46, incl. 12042',
       IF((SELECT COUNT(*) FROM rule_impossible_travel) = 46 AND (SELECT COUNT(*) FROM rule_impossible_travel WHERE txn_id = 12042) = 1, 'PASS', 'FAIL');

-- The five personas, found by SQL views alone
SELECT 'persona traveller  -> 12042 reason mentions Impossible travel',
       IF((SELECT reasons FROM v_transaction_risk WHERE txn_id = 12042) LIKE '%Impossible travel%', 'PASS', 'FAIL');
SELECT 'persona night_owl  -> 12043 reason mentions Off-hours',
       IF((SELECT reasons FROM v_transaction_risk WHERE txn_id = 12043) LIKE '%Off-hours%', 'PASS', 'FAIL');
SELECT 'persona burst      -> 12051 reason mentions Velocity',
       IF((SELECT reasons FROM v_transaction_risk WHERE txn_id = 12051) LIKE '%Velocity%', 'PASS', 'FAIL');
SELECT 'persona new_device_big -> 12052 has two reasons: High amount and New device',
       IF((SELECT reasons FROM v_transaction_risk WHERE txn_id = 12052) LIKE '%High amount%'
      AND (SELECT reasons FROM v_transaction_risk WHERE txn_id = 12052) LIKE '%New device%'
      AND (SELECT risk_score FROM v_transaction_risk WHERE txn_id = 12052) >= 2, 'PASS', 'FAIL');
SELECT 'persona bad_merchant -> 12053 to 12067 are all flagged (new device, usually high amount too)',
       IF((SELECT COUNT(*) FROM v_transaction_risk WHERE txn_id BETWEEN 12053 AND 12067) = 15, 'PASS', 'FAIL');

-- Indexes
SELECT 'composite index (account_id, txn_time) exists',
       IF((SELECT GROUP_CONCAT(column_name ORDER BY seq_in_index) FROM information_schema.statistics
           WHERE table_schema='sentinel' AND table_name='transactions' AND index_name='idx_txn_account_time') = 'account_id,txn_time', 'PASS', 'FAIL');
SELECT 'no redundant index on alerts(txn_id) or behaviour_baselines(account_id)',
       IF((SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='sentinel' AND index_name IN ('idx_alert_txn', 'idx_bb_account')) = 0, 'PASS', 'FAIL');

-- DCL
SELECT '3 roles and 3 users exist',
       IF((SELECT COUNT(*) FROM mysql.user WHERE User IN ('fraud_analyst','txn_app','db_admin','analyst_user','app_user','admin_user')) = 6, 'PASS', 'FAIL');
SELECT 'fraud_analyst has NO privilege on the raw transactions table',
       IF((SELECT COUNT(*) FROM mysql.tables_priv WHERE User='fraud_analyst' AND Db='sentinel' AND Table_name='transactions') = 0, 'PASS', 'FAIL');
SELECT 'fraud_analyst may read v_transaction_risk',
       IF((SELECT COUNT(*) FROM mysql.tables_priv WHERE User='fraud_analyst' AND Db='sentinel' AND Table_name='v_transaction_risk' AND FIND_IN_SET('Select', Table_priv)) = 1, 'PASS', 'FAIL');
SELECT 'txn_app may INSERT into transactions',
       IF((SELECT COUNT(*) FROM mysql.tables_priv WHERE User='txn_app' AND Db='sentinel' AND Table_name='transactions' AND FIND_IN_SET('Insert', Table_priv)) = 1, 'PASS', 'FAIL');
SELECT 'api_reader role and api_user exist',
       IF((SELECT COUNT(*) FROM mysql.user WHERE User IN ('api_reader','api_user')) = 2, 'PASS', 'FAIL');
SELECT 'api_reader may SELECT the 4 report views and rule_config (5 table grants)',
       IF((SELECT COUNT(*) FROM mysql.tables_priv WHERE User='api_reader' AND Db='sentinel' AND FIND_IN_SET('Select', Table_priv)
             AND Table_name IN ('v_active_alerts','v_daily_txn_summary','v_top_risky_users','v_alerts_by_city_day','rule_config')) = 5, 'PASS', 'FAIL');
SELECT 'api_reader has no privilege on raw transactions and no write privilege anywhere',
       IF((SELECT COUNT(*) FROM mysql.tables_priv WHERE User='api_reader' AND (Table_name='transactions' OR Table_priv <> 'Select')) = 0, 'PASS', 'FAIL');
