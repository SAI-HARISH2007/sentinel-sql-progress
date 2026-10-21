-- Week 10 demo — THE 90-SECOND DEMO. Run it in Workbench one block at a time, narrating as you go.
--     mysql -uroot -p sentinel < demo/01_fraud_demo.sql
-- It leaves the database exactly as it found it.
USE sentinel;

-- ---- 1. "Here is a normal customer": account 1 shops in business hours, from device 182, in Mumbai.
SELECT txn_id, amount, txn_time, device_id FROM transactions WHERE account_id = 1 AND txn_id < 12041 ORDER BY txn_time DESC LIMIT 5;
SELECT COUNT(*) AS alerts_before FROM alerts;

-- ---- 2. "Now someone pays 95,000 at 03:15 in the morning, from a device this account has never used, in another city."
INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount, txn_time, status)
VALUES (1, 1, 999, 4, 95000.00, '2026-09-02 03:15:00', 'success');
SET @new_txn = LAST_INSERT_ID();

-- ---- 3. "Nobody called anything. The database flagged it by itself, and says why."
SELECT alert_id, txn_id, risk_score, reasons, status FROM alerts WHERE txn_id = @new_txn;

-- ---- 4. "An analyst reviews it." The BEFORE trigger stamps reviewed_at; the AFTER trigger writes the audit trail.
SET @alert = (SELECT alert_id FROM alerts WHERE txn_id = @new_txn);
UPDATE alerts SET status = 'confirmed' WHERE alert_id = @alert;
SELECT status, reviewed_at FROM alerts WHERE alert_id = @alert;
SELECT table_name, record_id, old_value_json, new_value_json, changed_by FROM audit_log WHERE table_name = 'alerts' AND record_id = @alert;

-- ---- 5. "Thresholds are data." Make Rule 1 so strict it no longer fires, re-score, and watch the reason disappear.
UPDATE rule_config SET threshold_value = 50 WHERE rule_name = 'zscore';
CALL score_transaction(@new_txn);
SELECT reasons FROM alerts WHERE txn_id = @new_txn;                 -- "High amount" is gone
UPDATE rule_config SET threshold_value = 3.0 WHERE rule_name = 'zscore';
CALL score_transaction(@new_txn);
SELECT reasons FROM alerts WHERE txn_id = @new_txn;                 -- ... and back

-- ---- 6. "A burst": six payments from account 2 inside two minutes. The sixth exceeds the limit of 5 per 5 minutes.
--         (device 64 is one of account 2's known devices, so ONLY the velocity rule fires.)
INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount, txn_time) VALUES
    (2, 3, 64, 1, 110.00, '2026-09-03 11:00:00'),
    (2, 3, 64, 1, 120.00, '2026-09-03 11:00:20'),
    (2, 3, 64, 1, 130.00, '2026-09-03 11:00:40'),
    (2, 3, 64, 1, 140.00, '2026-09-03 11:01:00'),
    (2, 3, 64, 1, 150.00, '2026-09-03 11:01:20'),
    (2, 3, 64, 1, 160.00, '2026-09-03 11:01:40');
SELECT a.txn_id, a.risk_score, a.reasons
FROM alerts a JOIN transactions t ON t.txn_id = a.txn_id
WHERE t.account_id = 2 AND t.txn_time >= '2026-09-03' AND t.txn_time < '2026-09-04' AND a.reasons LIKE '%Velocity%';

-- ---- 7. Clean up so the demo can be run again. Deleting a transaction cascades to its alert (ON DELETE CASCADE).
DELETE FROM audit_log WHERE table_name = 'alerts' AND record_id = @alert;
DELETE FROM transactions WHERE txn_id = @new_txn;
DELETE FROM transactions WHERE account_id = 2 AND txn_time >= '2026-09-03' AND txn_time < '2026-09-04';
SELECT COUNT(*) AS alerts_after FROM alerts;          -- back to 21
