-- Week 9 demo — does an index actually help? Ask MySQL with EXPLAIN ANALYZE (it RUNS the query and reports real timings).
--     mysql -uroot -p sentinel < demo/explain_before_after.sql
-- Each experiment removes an index, measures, restores the index, measures again. The schema is unchanged at the end.
-- How to read the output: the innermost "->" line is where rows come from. "Table scan" = read every row.
-- "Index range scan" / "Index lookup" = jump straight to matching rows. "Sort" = an extra pass to order the rows.
-- "cost" is the optimiser's estimate (arbitrary units); "actual time" is milliseconds measured on this machine.
USE sentinel;

-- ============ Experiment 1: a date-range report (idx_txn_time) ====================================================
ALTER TABLE transactions DROP INDEX idx_txn_time;
SELECT '--- 1a. BEFORE: no index on txn_time' AS step;
EXPLAIN ANALYZE
SELECT COUNT(*), SUM(amount) FROM transactions WHERE txn_time >= '2026-08-15' AND txn_time < '2026-08-21';

CREATE INDEX idx_txn_time ON transactions (txn_time);
SELECT '--- 1b. AFTER: idx_txn_time' AS step;
EXPLAIN ANALYZE
SELECT COUNT(*), SUM(amount) FROM transactions WHERE txn_time >= '2026-08-15' AND txn_time < '2026-08-21';

-- ============ Experiment 2: one account's latest 50 transactions (idx_txn_account_time) ============================
-- "Before" means: only the plain foreign-key index on account_id that MySQL creates for fk_txn_account.
ALTER TABLE transactions DROP INDEX idx_txn_account_time, ADD INDEX fk_txn_account (account_id);
SELECT '--- 2a. BEFORE: index on account_id only' AS step;
EXPLAIN ANALYZE
SELECT txn_id, amount, txn_time FROM transactions WHERE account_id = 1 ORDER BY txn_time DESC LIMIT 50;

ALTER TABLE transactions DROP INDEX fk_txn_account, ADD INDEX idx_txn_account_time (account_id, txn_time);
SELECT '--- 2b. AFTER: composite (account_id, txn_time)' AS step;
EXPLAIN ANALYZE
SELECT txn_id, amount, txn_time FROM transactions WHERE account_id = 1 ORDER BY txn_time DESC LIMIT 50;

-- ============ Experiment 3: the same index on an uncorrelated lookup (merchant + time) ============================
SELECT '--- 3. merchant 50, newest first' AS step;
EXPLAIN ANALYZE
SELECT txn_id, amount FROM transactions WHERE merchant_id = 50 ORDER BY txn_time DESC LIMIT 20;
