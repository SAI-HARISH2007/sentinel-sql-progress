-- =============================================================================
-- Week 10 — STORED PROCEDURE: score one transaction against all six rules
-- 20_score_transaction.sql
-- =============================================================================
-- CALL score_transaction(12052);   -- scores that transaction and, if any rule fired, writes/updates its alert.
--
-- This is the SAME logic as the six rule views from Week 9, written procedurally for ONE transaction (a view
-- scans every transaction, which is far too slow to run on each insert). Each rule block follows one pattern:
--     read the rule's switch + threshold from rule_config  ->  compute the evidence  ->  compare  ->  add a point and a reason.
-- Only local variables are used (DECLARE). Session variables (@x) would leak between calls.
-- The alert's `reasons` column is a JSON array of readable strings; `risk_score` is the number of rules that fired.

USE sentinel;

DROP PROCEDURE IF EXISTS score_transaction;
DELIMITER //
CREATE PROCEDURE score_transaction(IN p_txn_id BIGINT)
BEGIN
    -- the transaction being scored
    DECLARE v_account_id  INT;
    DECLARE v_amount      DECIMAL(12,2);
    DECLARE v_txn_time    TIMESTAMP;
    DECLARE v_merchant_id INT;
    DECLARE v_device_id   INT;
    DECLARE v_location_id INT;
    -- the verdict
    DECLARE v_score   INT  DEFAULT 0;
    DECLARE v_reasons JSON DEFAULT JSON_ARRAY();
    -- scratch space
    DECLARE v_enabled   BOOLEAN;
    DECLARE v_threshold DECIMAL(12,4);
    DECLARE v_window    INT;
    DECLARE v_n         INT;
    DECLARE v_avg       DOUBLE;
    DECLARE v_sd        DOUBLE;
    DECLARE v_value     DOUBLE;
    DECLARE v_fp        VARCHAR(8);
    DECLARE v_prev_lat  DECIMAL(9,6);
    DECLARE v_prev_lon  DECIMAL(9,6);
    DECLARE v_prev_time TIMESTAMP;
    DECLARE v_lat       DECIMAL(9,6);
    DECLARE v_lon       DECIMAL(9,6);
    DECLARE v_km        DOUBLE;
    DECLARE v_hours     DOUBLE;
    DECLARE v_min_alerts DECIMAL(12,4);
    DECLARE v_m_total   INT;
    DECLARE v_m_alerts  INT;
    DECLARE v_p_total   INT;
    DECLARE v_p_alerts  INT;

    -- Load the transaction. If there is no such row the variables stay NULL.
    SELECT account_id, amount, txn_time, merchant_id, device_id, location_id
      INTO v_account_id, v_amount, v_txn_time, v_merchant_id, v_device_id, v_location_id
      FROM transactions WHERE txn_id = p_txn_id;
    IF v_account_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'score_transaction: no such transaction';
    END IF;

    -- ---------------------------------------------------------------- Rule 1: high amount (z-score)
    SELECT enabled, threshold_value INTO v_enabled, v_threshold FROM rule_config WHERE rule_name = 'zscore';
    IF v_enabled THEN
        SELECT AVG(amount), STDDEV_SAMP(amount), COUNT(*) INTO v_avg, v_sd, v_n
          FROM transactions WHERE account_id = v_account_id;
        IF v_n >= 5 AND v_sd > 0 THEN
            SET v_value = (v_amount - v_avg) / v_sd;
            IF v_value > v_threshold THEN
                SET v_score = v_score + 1;
                SET v_reasons = JSON_ARRAY_APPEND(v_reasons, '$', CONCAT('High amount (z=', ROUND(v_value, 2), ')'));
            END IF;
        END IF;
    END IF;

    -- ---------------------------------------------------------------- Rule 2: off-hours
    SELECT enabled, threshold_value INTO v_enabled, v_threshold FROM rule_config WHERE rule_name = 'off_hours';
    IF v_enabled THEN
        SELECT SUM(HOUR(txn_time) = HOUR(v_txn_time)), COUNT(*) INTO v_value, v_n
          FROM transactions WHERE account_id = v_account_id;
        IF v_value / v_n < v_threshold THEN
            SET v_score = v_score + 1;
            SET v_reasons = JSON_ARRAY_APPEND(v_reasons, '$',
                CONCAT('Off-hours (', HOUR(v_txn_time), ':00, only ', ROUND(100 * v_value / v_n, 2), '% of history)'));
        END IF;
    END IF;

    -- ---------------------------------------------------------------- Rule 3: new device
    SELECT enabled INTO v_enabled FROM rule_config WHERE rule_name = 'new_device';
    IF v_enabled THEN
        IF NOT EXISTS (SELECT 1 FROM account_devices WHERE account_id = v_account_id AND device_id = v_device_id) THEN
            SELECT LEFT(fingerprint_hash, 8) INTO v_fp FROM devices WHERE device_id = v_device_id;
            SET v_score = v_score + 1;
            SET v_reasons = JSON_ARRAY_APPEND(v_reasons, '$', CONCAT('New device (', v_fp, '...)'));
        END IF;
    END IF;

    -- ---------------------------------------------------------------- Rule 4: velocity
    SELECT enabled, threshold_value INTO v_enabled, v_threshold FROM rule_config WHERE rule_name = 'velocity';
    IF v_enabled THEN
        SELECT CAST(threshold_value AS UNSIGNED) INTO v_window FROM rule_config WHERE rule_name = 'velocity_window';
        SELECT COUNT(*) INTO v_n
          FROM transactions
         WHERE account_id = v_account_id
           AND txn_time BETWEEN DATE_SUB(v_txn_time, INTERVAL v_window MINUTE) AND v_txn_time;
        IF v_n > v_threshold THEN
            SET v_score = v_score + 1;
            SET v_reasons = JSON_ARRAY_APPEND(v_reasons, '$', CONCAT('Velocity spike (', v_n, ' in ', v_window, ' min)'));
        END IF;
    END IF;

    -- ---------------------------------------------------------------- Rule 5: impossible travel
    SELECT enabled, threshold_value INTO v_enabled, v_threshold FROM rule_config WHERE rule_name = 'impossible_travel';
    IF v_enabled THEN
        -- the account's previous transaction (same ordering the view's LAG() uses)
        SELECT l.latitude, l.longitude, t.txn_time INTO v_prev_lat, v_prev_lon, v_prev_time
          FROM transactions t JOIN locations l ON l.location_id = t.location_id
         WHERE t.account_id = v_account_id
           AND (t.txn_time < v_txn_time OR (t.txn_time = v_txn_time AND t.txn_id < p_txn_id))
         ORDER BY t.txn_time DESC, t.txn_id DESC
         LIMIT 1;
        IF v_prev_time IS NOT NULL THEN
            SELECT latitude, longitude INTO v_lat, v_lon FROM locations WHERE location_id = v_location_id;
            SET v_km    = haversine_km(v_prev_lat, v_prev_lon, v_lat, v_lon);
            SET v_hours = TIMESTAMPDIFF(SECOND, v_prev_time, v_txn_time) / 3600.0;
            IF v_hours > 0 AND v_km > 50 AND v_km / v_hours > v_threshold THEN
                SET v_score = v_score + 1;
                SET v_reasons = JSON_ARRAY_APPEND(v_reasons, '$',
                    CONCAT('Impossible travel (', ROUND(v_km, 2), ' km in ', ROUND(v_hours * 60, 1), ' min)'));
            END IF;
        END IF;
    END IF;

    -- ---------------------------------------------------------------- Rule 6: merchant risk
    SELECT enabled, threshold_value INTO v_enabled, v_threshold FROM rule_config WHERE rule_name = 'merchant_risk';
    IF v_enabled THEN
        SELECT COUNT(*) INTO v_m_total  FROM transactions WHERE merchant_id = v_merchant_id;
        SELECT COUNT(*) INTO v_m_alerts FROM alerts al JOIN transactions t ON t.txn_id = al.txn_id WHERE t.merchant_id = v_merchant_id;
        SELECT COUNT(*) INTO v_p_total  FROM transactions;
        SELECT COUNT(*) INTO v_p_alerts FROM alerts;
        SELECT threshold_value INTO v_min_alerts FROM rule_config WHERE rule_name = 'merchant_risk_min_alerts';
        IF v_m_total >= 3 AND v_m_alerts >= v_min_alerts AND v_p_alerts > 0 THEN
            SET v_value = (v_m_alerts / v_m_total) / (v_p_alerts / v_p_total);
            IF v_value > v_threshold THEN
                SET v_score = v_score + 1;
                SET v_reasons = JSON_ARRAY_APPEND(v_reasons, '$', CONCAT('Merchant risk (', ROUND(v_value, 2), 'x platform average)'));
            END IF;
        END IF;
    END IF;

    -- ---------------------------------------------------------------- Verdict
    IF v_score > 0 THEN
        INSERT INTO alerts (txn_id, rule_name, risk_score, reasons, status)
        VALUES (p_txn_id, 'combined', v_score, v_reasons, 'open')
        ON DUPLICATE KEY UPDATE risk_score = v_score, reasons = v_reasons;   -- re-scoring updates the existing alert
    ELSE
        DELETE FROM alerts WHERE txn_id = p_txn_id AND status = 'open';      -- no longer suspicious (e.g. a threshold was loosened)
    END IF;
END //
DELIMITER ;

-- Score many transactions in one go (used to back-fill history that was loaded before the trigger existed).
DROP PROCEDURE IF EXISTS backfill_alerts;
DELIMITER //
CREATE PROCEDURE backfill_alerts(IN p_from_txn BIGINT, IN p_to_txn BIGINT)
BEGIN
    DECLARE v_id BIGINT DEFAULT p_from_txn;
    WHILE v_id <= p_to_txn DO
        IF EXISTS (SELECT 1 FROM transactions WHERE txn_id = v_id) THEN
            CALL score_transaction(v_id);
        END IF;
        SET v_id = v_id + 1;
    END WHILE;
END //
DELIMITER ;
