-- Week 8 — GROUP BY: collapse many rows into one row per group, then aggregate each group
-- Rule of thumb: every column in SELECT must be either in GROUP BY or inside an aggregate function.
USE sentinel;

-- One row per status
SELECT status, COUNT(*) AS txns, ROUND(SUM(amount), 2) AS total, ROUND(AVG(amount), 2) AS avg_amount
FROM transactions
GROUP BY status;

-- One row per calendar month (group by an expression)
SELECT DATE_FORMAT(txn_time, '%Y-%m') AS month, COUNT(*) AS txns, ROUND(SUM(amount)) AS total
FROM transactions
GROUP BY DATE_FORMAT(txn_time, '%Y-%m')
ORDER BY month;

-- Hour-of-day histogram for account 1.  THIS is the raw material of Rule 2 (off-hours).
SELECT HOUR(txn_time) AS hr,
       COUNT(*) AS txns,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM transactions WHERE account_id = 1), 2) AS pct_of_history
FROM transactions
WHERE account_id = 1
GROUP BY HOUR(txn_time)
ORDER BY hr;

-- One row per account: the numbers Rule 1 (z-score) compares against
SELECT account_id, COUNT(*) AS txns, ROUND(AVG(amount), 2) AS avg_amount, ROUND(STDDEV_SAMP(amount), 2) AS stddev_amount
FROM transactions
GROUP BY account_id
ORDER BY txns DESC
LIMIT 5;

-- Group by TWO columns, and add a grand-total row with WITH ROLLUP
SELECT account_id, status, COUNT(*) AS txns
FROM transactions
WHERE account_id IN (1, 2)
GROUP BY account_id, status WITH ROLLUP;

-- GROUP_CONCAT glues the values of a group into one string
SELECT account_id, COUNT(*) AS known_devices, GROUP_CONCAT(device_id ORDER BY device_id) AS device_ids
FROM account_devices
WHERE account_id <= 3
GROUP BY account_id;

-- Grouping across a join: busiest merchants
SELECT m.merchant_id, m.merchant_name, COUNT(*) AS txns, ROUND(AVG(t.amount), 2) AS avg_amount
FROM transactions t JOIN merchants m ON m.merchant_id = t.merchant_id
GROUP BY m.merchant_id, m.merchant_name
ORDER BY txns DESC
LIMIT 5;
