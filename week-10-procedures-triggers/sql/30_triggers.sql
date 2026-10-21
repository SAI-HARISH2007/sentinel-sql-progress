-- =============================================================================
-- Week 10 — TRIGGERS
-- 30_triggers.sql — code the database runs by itself when rows change
-- =============================================================================
-- A trigger is attached to a table + an event (INSERT / UPDATE / DELETE) + a moment (BEFORE / AFTER).
-- Inside it, NEW is the row being written and OLD is the row as it was (UPDATE/DELETE only).
-- Nobody calls a trigger. That is the whole point: no application can forget to run the fraud check.

USE sentinel;

-- 1. AFTER INSERT on transactions: score every new transaction the moment it is stored.
--    It is AFTER (not BEFORE) because the scoring procedure reads the transaction, and a BEFORE trigger runs before
--    the row exists. A row-level trigger fires once per inserted row, even for a multi-row INSERT.
DROP TRIGGER IF EXISTS trg_after_txn_insert;
DELIMITER //
CREATE TRIGGER trg_after_txn_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    CALL score_transaction(NEW.txn_id);
END //
DELIMITER ;

-- 2. BEFORE UPDATE on alerts: when an analyst moves an alert out of 'open', stamp the review time automatically.
--    BEFORE lets us change NEW before it is written (SET NEW.col = ...). An AFTER trigger could not.
DROP TRIGGER IF EXISTS trg_before_alert_update;
DELIMITER //
CREATE TRIGGER trg_before_alert_update
BEFORE UPDATE ON alerts
FOR EACH ROW
BEGIN
    IF OLD.status = 'open' AND NEW.status <> 'open' AND NEW.reviewed_at IS NULL THEN
        SET NEW.reviewed_at = CURRENT_TIMESTAMP;
    END IF;
END //
DELIMITER ;

-- 3. AFTER UPDATE on alerts: write every status change to audit_log (who, when, from what, to what).
--    Triggers run with the DEFINER's rights, so an analyst who can only UPDATE alerts still causes an audit_log row.
--    changed_by uses USER(), not CURRENT_USER(): inside a trigger CURRENT_USER() is the definer (root), which would
--    make every audit row blame root. (The original project had exactly this bug.)
DROP TRIGGER IF EXISTS trg_after_alert_update;
DELIMITER //
CREATE TRIGGER trg_after_alert_update
AFTER UPDATE ON alerts
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO audit_log (table_name, record_id, action, old_value_json, new_value_json, changed_by)
        VALUES ('alerts', NEW.alert_id, 'UPDATE',
                JSON_OBJECT('status', OLD.status),
                JSON_OBJECT('status', NEW.status),
                USER());
    END IF;
END //
DELIMITER ;
