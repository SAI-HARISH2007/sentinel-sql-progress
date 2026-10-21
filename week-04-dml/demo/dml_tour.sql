-- Week 4 demo — INSERT, SELECT, UPDATE, DELETE on the real project tables.
-- Uses ids >= 90000 for its own rows and removes them at the end, so the seed data is untouched.
--     mysql -uroot -p sentinel < demo/dml_tour.sql
USE sentinel;
DROP TABLE IF EXISTS users_demo_copy;

-- ============================ INSERT ==========================================
-- (a) one row, columns named (always name the columns: the statement survives a column being added later)
INSERT INTO users (user_id, full_name, email, phone, date_of_birth)
VALUES (90001, 'Demo One', 'demo1@example.com', '+919000000001', '2005-05-05');

-- (b) several rows in ONE statement (one round trip, one implicit transaction)
INSERT INTO users (user_id, full_name, email) VALUES
    (90002, 'Demo Two',   'demo2@example.com'),
    (90003, 'Demo Three', 'demo3@example.com');

-- (c) INSERT ... SELECT: copy rows from one table into another
CREATE TABLE users_demo_copy LIKE users;
INSERT INTO users_demo_copy SELECT * FROM users WHERE user_id >= 90000;

-- (d) omit columns -> DEFAULTs from Week 3 fill in: savings, balance 0.00, active, created_at = now
INSERT INTO accounts (account_id, user_id) VALUES (90001, 90001);

-- ============================ SELECT ==========================================
SELECT * FROM users WHERE user_id >= 90000;
SELECT account_id, account_type, balance, status, created_at FROM accounts WHERE account_id = 90001;
SELECT merchant_id, merchant_name, city FROM merchants WHERE city = 'Mumbai' ORDER BY merchant_name LIMIT 5;
SELECT DISTINCT status FROM transactions;
SELECT txn_id, account_id, amount, txn_time FROM transactions ORDER BY amount DESC LIMIT 5;  -- the biggest transaction is the 95,000 persona

-- ============================ UPDATE ==========================================
-- ALWAYS check the WHERE clause. "UPDATE users SET phone = ..." with no WHERE rewrites EVERY row.
UPDATE users    SET phone = '+919999999999'    WHERE user_id = 90002;
UPDATE accounts SET balance = balance + 5000   WHERE account_id = 90001;
SELECT account_id, balance FROM accounts WHERE account_id = 90001;                           -- 5000.00

-- Tuning the fraud detector is an UPDATE. Note updated_at changes by itself (ON UPDATE CURRENT_TIMESTAMP, Week 3).
SELECT rule_name, threshold_value, updated_at FROM rule_config WHERE rule_name = 'zscore';
UPDATE rule_config SET threshold_value = 2.5 WHERE rule_name = 'zscore';
SELECT rule_name, threshold_value, updated_at FROM rule_config WHERE rule_name = 'zscore';
UPDATE rule_config SET threshold_value = 3.0 WHERE rule_name = 'zscore';                      -- put it back

-- ============================ DELETE ==========================================
DELETE FROM users WHERE user_id = 90003;                       -- one row
SELECT COUNT(*) AS demo_users_left FROM users WHERE user_id >= 90000;                         -- 2
DELETE FROM users WHERE user_id >= 90000;                      -- the rest; ON DELETE CASCADE also removes account 90001
SELECT COUNT(*) AS demo_accounts_left FROM accounts WHERE account_id = 90001;                 -- 0

DROP TABLE users_demo_copy;
