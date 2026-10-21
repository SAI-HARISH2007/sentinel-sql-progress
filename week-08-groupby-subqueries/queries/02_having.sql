-- Week 8 — HAVING: filter GROUPS (after aggregation). WHERE filters ROWS (before aggregation).
USE sentinel;

-- WHERE first (only successful txns are counted), then HAVING (only groups with 30+ of them survive)
SELECT account_id, COUNT(*) AS successful_txns
FROM transactions
WHERE status = 'success'
GROUP BY account_id
HAVING COUNT(*) >= 30
ORDER BY successful_txns DESC
LIMIT 5;

-- You cannot put an aggregate in WHERE:   WHERE COUNT(*) >= 30   -> ERROR 1111 Invalid use of group function

-- Merchants whose average ticket is unusually high
SELECT merchant_id, COUNT(*) AS txns, ROUND(AVG(amount), 2) AS avg_amount
FROM transactions
GROUP BY merchant_id
HAVING AVG(amount) > 3000
ORDER BY avg_amount DESC;

-- FRAUD RULE 4: VELOCITY.  Self-join (Week 7) gives, for each transaction t1, every transaction of the same
-- account in the 5 minutes up to and including t1.  GROUP BY t1, HAVING COUNT(*) > limit keeps the bursts.
SELECT t1.account_id, t1.txn_id, t1.txn_time, COUNT(*) AS txns_in_window
FROM transactions t1
JOIN transactions t2 ON t2.account_id = t1.account_id
                    AND t2.txn_time BETWEEN DATE_SUB(t1.txn_time, INTERVAL 5 MINUTE) AND t1.txn_time
GROUP BY t1.account_id, t1.txn_id, t1.txn_time
HAVING COUNT(*) > (SELECT threshold_value FROM rule_config WHERE rule_name = 'velocity')
ORDER BY t1.account_id, t1.txn_time;
-- Expected: 3 rows, all account 1 on 17 Aug: the 6th, 7th and 8th transaction of the burst (counts 6, 7, 8).
