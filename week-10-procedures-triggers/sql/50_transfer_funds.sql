-- =============================================================================
-- Week 10 — TRANSACTION MANAGEMENT: transfer_funds()
-- 50_transfer_funds.sql — move money between two accounts, all-or-nothing
-- =============================================================================
-- ACID in one procedure:
--   Atomicity   debit + credit + the transaction record happen together or not at all (COMMIT / ROLLBACK)
--   Consistency balances never go negative (checked here AND by the CHECK constraint from Week 3)
--   Isolation   SELECT ... FOR UPDATE locks the two account rows, so two transfers cannot both spend the same money
--   Durability  after COMMIT the change survives a crash (InnoDB redo log)
-- Locks are always taken in ASCENDING account_id order. If A->B and B->A ran at the same time and each locked its
-- own account first, they would wait for each other forever (deadlock). One agreed order makes that impossible.
--
-- The debit is also recorded in `transactions` (merchant 1 stands in for "transfer"), so the AFTER INSERT trigger
-- from file 30 scores it like any other payment. Only the sender gets a row: money RECEIVED is not a purchase and
-- must not distort the receiver's spending statistics.

USE sentinel;

DROP PROCEDURE IF EXISTS transfer_funds;
DELIMITER //
CREATE PROCEDURE transfer_funds(
    IN p_from_account INT,
    IN p_to_account   INT,
    IN p_amount       DECIMAL(12,2),
    IN p_device_id    INT,
    IN p_location_id  INT
)
BEGIN
    DECLARE v_from_balance DECIMAL(14,2);
    DECLARE v_from_status  VARCHAR(20);
    DECLARE v_to_status    VARCHAR(20);

    -- Any unexpected error (bad foreign key, deadlock, ...): undo everything, then re-raise it to the caller.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validate before touching anything.
    IF p_amount IS NULL OR p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transfer amount must be positive';
    END IF;
    IF p_from_account = p_to_account THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot transfer to the same account';
    END IF;

    START TRANSACTION;

    -- Lock both rows, lowest id first.
    IF p_from_account < p_to_account THEN
        SELECT balance, status INTO v_from_balance, v_from_status FROM accounts WHERE account_id = p_from_account FOR UPDATE;
        SELECT status          INTO v_to_status                   FROM accounts WHERE account_id = p_to_account   FOR UPDATE;
    ELSE
        SELECT status          INTO v_to_status                   FROM accounts WHERE account_id = p_to_account   FOR UPDATE;
        SELECT balance, status INTO v_from_balance, v_from_status FROM accounts WHERE account_id = p_from_account FOR UPDATE;
    END IF;

    IF v_from_status IS NULL OR v_to_status IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Source or destination account does not exist';
    END IF;
    IF v_from_status <> 'active' THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Source account is not active';
    END IF;
    IF v_to_status <> 'active' THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Destination account is not active';
    END IF;
    IF v_from_balance < p_amount THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;

    UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_from_account;
    UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_to_account;

    INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount, status)
    VALUES (p_from_account, 1, p_device_id, p_location_id, p_amount, 'success');

    COMMIT;

    SELECT 'Transfer completed' AS result, p_amount AS amount,
           (SELECT balance FROM accounts WHERE account_id = p_from_account) AS sender_balance_now,
           (SELECT balance FROM accounts WHERE account_id = p_to_account)   AS receiver_balance_now;
END //
DELIMITER ;
