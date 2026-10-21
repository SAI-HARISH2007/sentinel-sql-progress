-- Week 5 — AGGREGATE functions: many rows in, ONE value out
USE sentinel;

-- Whole table
SELECT COUNT(*)                   AS all_rows,
       COUNT(DISTINCT account_id) AS accounts_that_transacted,
       SUM(amount)                AS total_amount,
       ROUND(AVG(amount), 2)      AS avg_amount,
       MIN(amount)                AS smallest,
       MAX(amount)                AS largest,
       ROUND(STDDEV_SAMP(amount), 2) AS sample_stddev,
       ROUND(VARIANCE(amount), 0)    AS variance
FROM transactions;

-- COUNT(*) counts rows; COUNT(column) skips NULLs. metadata_json is never filled, phone always is.
SELECT COUNT(*) AS rows_in_table, COUNT(metadata_json) AS with_metadata FROM transactions;

-- One account's behaviour. These two numbers (average, standard deviation) ARE the baseline that Rule 1 compares against.
SELECT COUNT(*)                     AS txns,
       ROUND(AVG(amount), 2)        AS avg_amount,
       ROUND(STDDEV_SAMP(amount), 2) AS stddev_amount,
       MAX(amount)                  AS biggest
FROM transactions
WHERE account_id = 1;

-- Aggregate + WHERE on a different column
SELECT COUNT(*) AS failed_txns, ROUND(SUM(amount), 2) AS failed_value FROM transactions WHERE status = 'failed';
SELECT MIN(txn_time) AS first_txn, MAX(txn_time) AS last_txn FROM transactions;
