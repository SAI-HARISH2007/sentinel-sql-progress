-- Week 3 demo — make every constraint FIRE. Each statement marked "EXPECT ERROR" must fail.
-- Run with --force so the script continues after each error, and read the error codes:
--     mysql -uroot -p --force sentinel < demo/constraint_violations.sql
-- Everything happens inside a transaction that is rolled back, so no data is left behind.
USE sentinel;
START TRANSACTION;

INSERT INTO merchant_categories (category_id, category_name) VALUES (99001, 'Demo category');   -- fine

-- 1. PRIMARY KEY: the same id twice
INSERT INTO merchant_categories (category_id, category_name) VALUES (99001, 'Another name');      -- EXPECT ERROR  1062 Duplicate entry '99001' for key 'PRIMARY'

-- 2. UNIQUE: the same category name twice
INSERT INTO merchant_categories (category_name) VALUES ('Demo category');                         -- EXPECT ERROR  1062 Duplicate entry ... for key 'category_name'

-- 3. NOT NULL: a user with no name
INSERT INTO users (full_name, email) VALUES (NULL, 'nobody@example.com');                         -- EXPECT ERROR  1048 Column 'full_name' cannot be null

-- 4. FOREIGN KEY: an account whose user does not exist
INSERT INTO accounts (user_id) VALUES (99999999);                                                 -- EXPECT ERROR  1452 Cannot add or update a child row

-- 5. CHECK: a transaction for a negative amount
INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount)
VALUES (1, 1, 1, 1, -500.00);                                                                    -- EXPECT ERROR  3819 Check constraint 'chk_txn_amount' is violated

-- 6. FOREIGN KEY ... ON DELETE RESTRICT: delete a category that a merchant still uses
INSERT INTO merchants (merchant_name, category_id, city, latitude, longitude)
VALUES ('Demo Merchant', 99001, 'Pune', 18.5204, 73.8567);                                        -- fine
DELETE FROM merchant_categories WHERE category_id = 99001;                                        -- EXPECT ERROR  1451 Cannot delete or update a parent row

-- 7. FOREIGN KEY ... ON DELETE CASCADE: this one SUCCEEDS and takes the child rows with it
INSERT INTO users (user_id, full_name, email) VALUES (99001, 'Cascade Demo', 'cascade@example.com');
INSERT INTO accounts (account_id, user_id) VALUES (99001, 99001);          -- defaults kick in: savings, balance 0.00, active
SELECT account_id, account_type, balance, status FROM accounts WHERE account_id = 99001;          -- DEFAULT values visible
DELETE FROM users WHERE user_id = 99001;
SELECT COUNT(*) AS accounts_left_after_cascade FROM accounts WHERE account_id = 99001;            -- 0

ROLLBACK;
