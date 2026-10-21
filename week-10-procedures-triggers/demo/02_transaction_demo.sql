-- Week 10 demo — transaction control: COMMIT, ROLLBACK, and transfer_funds().  Leaves balances as they were.
USE sentinel;

SELECT account_id, balance FROM accounts WHERE account_id IN (2, 3);
SELECT balance INTO @b2 FROM accounts WHERE account_id = 2;
SELECT balance INTO @b3 FROM accounts WHERE account_id = 3;

-- ---- A. ROLLBACK by hand: change, look, undo.
START TRANSACTION;
UPDATE accounts SET balance = balance - 500 WHERE account_id = 2;
SELECT balance AS inside_transaction FROM accounts WHERE account_id = 2;
ROLLBACK;
SELECT balance AS after_rollback FROM accounts WHERE account_id = 2;           -- unchanged

-- ---- B. The same change with COMMIT would be permanent. (Not run here.)

-- ---- C. transfer_funds: debit + credit + transaction record, atomically.
CALL transfer_funds(2, 3, 1000.00, 1, 1);
SELECT account_id, balance FROM accounts WHERE account_id IN (2, 3);           -- 2 is 1000 lower, 3 is 1000 higher
SELECT txn_id, account_id, amount FROM transactions WHERE account_id = 2 ORDER BY txn_id DESC LIMIT 1;

-- ---- D. Clean up: put the money back and remove the transfer's transaction row (cascades to its alert).
DELETE FROM transactions WHERE account_id = 2 AND amount = 1000.00 AND txn_id > 12067;
UPDATE accounts SET balance = @b2 WHERE account_id = 2;
UPDATE accounts SET balance = @b3 WHERE account_id = 3;
SELECT account_id, balance FROM accounts WHERE account_id IN (2, 3);           -- as at the start
