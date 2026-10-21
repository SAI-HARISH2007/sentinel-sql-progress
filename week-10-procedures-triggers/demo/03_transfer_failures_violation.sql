-- Week 10 demo — transfer_funds must REFUSE bad requests and leave everything untouched.
-- Each line marked "EXPECT ERROR" must fail. Run with --force:   mysql -uroot -p --force sentinel < demo/03_transfer_failures_violation.sql
USE sentinel;
SELECT SUM(balance) AS total_money_before FROM accounts;

CALL transfer_funds(2, 3, 999999999.00, 1, 1);     -- EXPECT ERROR  45000 Insufficient funds
CALL transfer_funds(2, 3, -50.00, 1, 1);           -- EXPECT ERROR  45000 Transfer amount must be positive
CALL transfer_funds(2, 2, 10.00, 1, 1);            -- EXPECT ERROR  45000 Cannot transfer to the same account
CALL transfer_funds(2, 99999, 10.00, 1, 1);        -- EXPECT ERROR  45000 Source or destination account does not exist

SELECT SUM(balance) AS total_money_after FROM accounts;      -- identical: nothing leaked
SELECT COUNT(*) AS transactions_added FROM transactions WHERE txn_id > 12067;
