-- Week 6 — LOGICAL operators:  AND  OR  NOT  XOR     (and why parentheses matter)
USE sentinel;

-- First-cut fraud screen: a big payment in the small hours.
SELECT txn_id, account_id, amount, txn_time
FROM transactions
WHERE amount > 5000
  AND (HOUR(txn_time) < 5 OR HOUR(txn_time) >= 23)
ORDER BY amount DESC
LIMIT 8;

-- Precedence: AND binds tighter than OR. These two look similar and are NOT:
SELECT COUNT(*) AS with_brackets
FROM transactions WHERE amount > 5000 AND (status = 'failed' OR status = 'pending');
SELECT COUNT(*) AS without_brackets            -- = (amount > 5000 AND failed) OR pending  -> far more rows
FROM transactions WHERE amount > 5000 AND status = 'failed' OR status = 'pending';

-- NOT negates; XOR is "one or the other but not both"
SELECT COUNT(*) AS not_failed          FROM transactions WHERE NOT (status = 'failed');
SELECT COUNT(*) AS big_xor_failed      FROM transactions WHERE (amount > 20000) XOR (status = 'failed');
