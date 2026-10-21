-- Week 10 assertions. Every row must say PASS.
USE sentinel;

SELECT '1 function + 4 procedures exist',
       IF((SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='sentinel') = 5, 'PASS', 'FAIL');
SELECT '3 triggers exist (after-insert score, before-update stamp, after-update audit)',
       IF((SELECT GROUP_CONCAT(trigger_name ORDER BY trigger_name) FROM information_schema.triggers WHERE trigger_schema='sentinel')
          = 'trg_after_alert_update,trg_after_txn_insert,trg_before_alert_update', 'PASS', 'FAIL');
SELECT 'nightly event is enabled', IF((SELECT status FROM information_schema.events WHERE event_schema='sentinel' AND event_name='evt_refresh_baselines') = 'ENABLED', 'PASS', 'FAIL');

SELECT 'haversine_km(Delhi, Chennai) is about 1768 km',
       IF((SELECT haversine_km(28.7041, 77.1025, 13.0827, 80.2707)) BETWEEN 1760 AND 1775, 'PASS', 'FAIL');
SELECT 'rule_impossible_travel still returns 46 rows after refactoring to use the function',
       IF((SELECT COUNT(*) FROM rule_impossible_travel) = 46, 'PASS', 'FAIL');

-- The back-filled personas
SELECT '21 persona alerts exist (6 on account 1 + 15 at the bad merchant)',
       IF((SELECT COUNT(*) FROM alerts WHERE txn_id BETWEEN 12041 AND 12067) = 21, 'PASS', 'FAIL');
SELECT 'traveller 12042 -> Impossible travel',   IF((SELECT reasons FROM alerts WHERE txn_id = 12042) LIKE '%Impossible travel%', 'PASS', 'FAIL');
SELECT 'night_owl 12043 -> Off-hours',           IF((SELECT reasons FROM alerts WHERE txn_id = 12043) LIKE '%Off-hours%',        'PASS', 'FAIL');
SELECT 'burst 12049-12051 -> Velocity (3 alerts)', IF((SELECT COUNT(*) FROM alerts WHERE txn_id BETWEEN 12049 AND 12051 AND reasons LIKE '%Velocity%') = 3, 'PASS', 'FAIL');
SELECT 'new_device_big 12052 -> High amount + New device',
       IF((SELECT reasons FROM alerts WHERE txn_id = 12052) LIKE '%High amount%' AND (SELECT reasons FROM alerts WHERE txn_id = 12052) LIKE '%New device%', 'PASS', 'FAIL');
SELECT 'bad_merchant -> Merchant risk appears once the merchant has 3 alerts (12056 onward = 12 alerts)',
       IF((SELECT COUNT(*) FROM alerts WHERE txn_id BETWEEN 12053 AND 12067 AND reasons LIKE '%Merchant risk%') = 12, 'PASS', 'FAIL');
SELECT 'rule_merchant_risk flags merchant 50 and only merchant 50',
       IF((SELECT COUNT(DISTINCT merchant_id) FROM rule_merchant_risk) = 1 AND (SELECT MIN(merchant_id) FROM rule_merchant_risk) = 50, 'PASS', 'FAIL');

-- The trigger, live. Inside a transaction that is rolled back, so nothing is left behind.
START TRANSACTION;
INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount, txn_time, status)
VALUES (1, 1, 999, 4, 95000.00, '2026-09-02 03:15:00', 'success');
SET @t = LAST_INSERT_ID();
SELECT 'TRIGGER: a 95,000 payment at 03:15 from device 999 creates an alert by itself',
       IF((SELECT COUNT(*) FROM alerts WHERE txn_id = @t) = 1, 'PASS', 'FAIL');
SELECT 'TRIGGER: that alert carries 3 reasons (High amount, Off-hours, New device)',
       IF((SELECT JSON_LENGTH(reasons) FROM alerts WHERE txn_id = @t) = 3, 'PASS', 'FAIL');
UPDATE alerts SET status = 'confirmed' WHERE txn_id = @t;
SELECT 'TRIGGER: closing the alert stamps reviewed_at (BEFORE trigger)',
       IF((SELECT reviewed_at IS NOT NULL FROM alerts WHERE txn_id = @t) = 1, 'PASS', 'FAIL');
SELECT 'TRIGGER: closing the alert writes one audit_log row (AFTER trigger)',
       IF((SELECT COUNT(*) FROM audit_log WHERE table_name = 'alerts' AND record_id = (SELECT alert_id FROM alerts WHERE txn_id = @t)) = 1, 'PASS', 'FAIL');
ROLLBACK;
SELECT 'ROLLBACK left no trace: still 12067 transactions and 21 alerts',
       IF((SELECT COUNT(*) FROM transactions) = 12067 AND (SELECT COUNT(*) FROM alerts) = 21, 'PASS', 'FAIL');

-- A normal-looking transaction must NOT raise an alert (account 3, a known device, business hours, modest amount)
START TRANSACTION;
INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount, txn_time, status)
SELECT 3, 5, ad.device_id, 1, 800.00, '2026-09-04 13:00:00', 'success' FROM account_devices ad WHERE ad.account_id = 3 LIMIT 1;
SET @t = LAST_INSERT_ID();
SELECT 'TRIGGER: an ordinary payment creates no alert (no false alarm on this one)',
       IF((SELECT COUNT(*) FROM alerts WHERE txn_id = @t) = 0, 'PASS', 'FAIL');
ROLLBACK;

-- Baseline refresh procedure
CALL refresh_behaviour_baselines();
SELECT 'refresh_behaviour_baselines() rebuilds 597 rows', IF((SELECT COUNT(*) FROM behaviour_baselines) = 597, 'PASS', 'FAIL');

-- Audit trigger uses USER(), not CURRENT_USER()
SELECT 'audit trigger records USER() (connected user), not the definer',
       IF((SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema='sentinel' AND trigger_name='trg_after_alert_update' AND action_statement LIKE '%USER()%' AND action_statement NOT LIKE '%CURRENT_USER()%') = 1, 'PASS', 'FAIL');

-- txn_app may call transfer_funds (routine-level grant)
SELECT 'txn_app has EXECUTE on transfer_funds',
       IF((SELECT COUNT(*) FROM mysql.procs_priv WHERE User='txn_app' AND Db='sentinel' AND Routine_name='transfer_funds' AND FIND_IN_SET('Execute', Proc_priv)) = 1, 'PASS', 'FAIL');
