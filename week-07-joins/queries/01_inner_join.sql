-- Week 7 — INNER JOIN: combine rows from several tables where the keys match
-- Rows with no match on either side disappear. This is the join behind every "alert context" view.
USE sentinel;

-- The full story of the 95,000 payment: who, which account, which merchant, where, on what device
SELECT t.txn_id,
       u.full_name,
       a.account_id,
       t.amount,
       m.merchant_name,
       mc.category_name,
       l.city        AS txn_city,
       d.device_type,
       d.os,
       t.txn_time
FROM transactions t
INNER JOIN accounts            a  ON a.account_id  = t.account_id
INNER JOIN users               u  ON u.user_id     = a.user_id
INNER JOIN merchants           m  ON m.merchant_id = t.merchant_id
INNER JOIN merchant_categories mc ON mc.category_id = m.category_id
INNER JOIN locations           l  ON l.location_id = t.location_id
INNER JOIN devices             d  ON d.device_id   = t.device_id
WHERE t.txn_id = 12052;

-- Same idea in the older "comma" style (WHERE does the matching). Prefer JOIN ... ON: it keeps the matching
-- condition apart from the filtering condition, and you cannot forget it (forgetting it gives a CROSS JOIN).
SELECT t.txn_id, m.merchant_name
FROM transactions t, merchants m
WHERE m.merchant_id = t.merchant_id AND t.txn_id = 12052;

-- Inner join also FILTERS: only merchants that have at least one transaction appear
SELECT COUNT(*) AS merchants_with_txns FROM merchants m INNER JOIN transactions t ON t.merchant_id = m.merchant_id;   -- one row per matching pair!
SELECT COUNT(DISTINCT m.merchant_id) AS distinct_merchants_with_txns FROM merchants m INNER JOIN transactions t ON t.merchant_id = m.merchant_id;

-- CROSS JOIN: every combination (no ON). 3 x 3 = 9 rows. Rarely what you want by accident.
SELECT a.status AS acct_status, b.status AS txn_status
FROM (SELECT 'active' AS status UNION SELECT 'frozen' UNION SELECT 'closed') a
CROSS JOIN (SELECT 'success' AS status UNION SELECT 'pending' UNION SELECT 'failed') b;
