-- Week 8 — SUBQUERIES: a SELECT inside another statement
USE sentinel;

-- 1. SCALAR subquery (returns one value): transactions bigger than the overall average
SELECT COUNT(*) AS above_average
FROM transactions WHERE amount > (SELECT AVG(amount) FROM transactions);

-- 2. IN subquery (returns a list): transactions made on devices of type 'tablet'
SELECT COUNT(*) AS tablet_txns
FROM transactions WHERE device_id IN (SELECT device_id FROM devices WHERE device_type = 'tablet');

-- 3. NOT IN / NOT EXISTS: accounts that have never transacted (careful: NOT IN returns nothing if the list contains a NULL)
SELECT COUNT(*) AS accounts_without_txns
FROM accounts a WHERE NOT EXISTS (SELECT 1 FROM transactions t WHERE t.account_id = a.account_id);

-- 4. EXISTS: does this account have at least one payment over 50,000?
SELECT a.account_id FROM accounts a
WHERE EXISTS (SELECT 1 FROM transactions t WHERE t.account_id = a.account_id AND t.amount > 50000)
ORDER BY a.account_id;

-- 5. CORRELATED subquery (re-evaluated per outer row): each payment compared with ITS OWN account's average
SELECT t.txn_id, t.account_id, t.amount
FROM transactions t
WHERE t.account_id = 1
  AND t.amount > 2 * (SELECT AVG(t2.amount) FROM transactions t2 WHERE t2.account_id = t.account_id)
ORDER BY t.amount DESC;

-- 6. DERIVED TABLE (subquery in FROM): per-account stats first, then filter on them
SELECT s.account_id, s.txns, s.avg_amount
FROM (SELECT account_id, COUNT(*) AS txns, ROUND(AVG(amount), 2) AS avg_amount
      FROM transactions GROUP BY account_id) AS s
WHERE s.txns >= 30 AND s.avg_amount > 3000
ORDER BY s.avg_amount DESC;

-- 7. ALL / ANY: bigger than EVERY / SOME value in the list
SELECT COUNT(*) AS bigger_than_every_failed_txn
FROM transactions WHERE amount > ALL (SELECT amount FROM transactions WHERE status = 'failed');

-- 8. Subquery in SELECT (one extra column per row)
SELECT m.merchant_id, m.merchant_name,
       (SELECT COUNT(*) FROM transactions t WHERE t.merchant_id = m.merchant_id) AS txns
FROM merchants m ORDER BY txns DESC LIMIT 3;
