-- Week 6 — PROJECT STEP: a "first-cut fraud screen" built only from operators.
-- No statistics yet, just fixed rules of thumb. Weeks 7-10 replace each rule of thumb with something smarter.
-- Notice how many innocent transactions it also catches: fixed thresholds produce false positives, which is
-- exactly why Rule 1 compares each amount with that account's OWN history.
USE sentinel;

SELECT txn_id, account_id, amount, HOUR(txn_time) AS hr, status,
       CONCAT_WS(', ',
           IF(amount >= 50000, 'very large amount', NULL),
           IF(HOUR(txn_time) BETWEEN 0 AND 4 AND amount > 5000, 'large night payment', NULL),
           IF(device_id = 999, 'device 999 (never seen)', NULL)
       ) AS why
FROM transactions
WHERE amount >= 50000
   OR (HOUR(txn_time) BETWEEN 0 AND 4 AND amount > 5000)
   OR device_id = 999
ORDER BY amount DESC
LIMIT 15;

SELECT COUNT(*) AS screened_in
FROM transactions
WHERE amount >= 50000
   OR (HOUR(txn_time) BETWEEN 0 AND 4 AND amount > 5000)
   OR device_id = 999;
