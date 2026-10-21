-- Week 6 — SET operators:  UNION  UNION ALL  INTERSECT  EXCEPT
-- Both queries must return the same number of columns with compatible types.
-- (Oracle calls EXCEPT "MINUS". INTERSECT / EXCEPT need MySQL 8.0.31 or newer.)
USE sentinel;

-- Two lists of accounts:  A = made a payment over 50,000   B = made a payment over 10,000 between midnight and 5 a.m.
-- A
SELECT DISTINCT account_id FROM transactions WHERE amount > 50000 ORDER BY account_id LIMIT 5;

-- UNION: in A or B (duplicates removed) = "accounts worth a second look"
SELECT COUNT(*) AS a_or_b FROM (
    SELECT account_id FROM transactions WHERE amount > 50000
    UNION
    SELECT account_id FROM transactions WHERE HOUR(txn_time) < 5 AND amount > 10000
) AS u;

-- UNION ALL keeps duplicates (and is faster because it skips the de-duplication)
SELECT COUNT(*) AS rows_union_all FROM (
    SELECT account_id FROM transactions WHERE amount > 50000
    UNION ALL
    SELECT account_id FROM transactions WHERE HOUR(txn_time) < 5 AND amount > 10000
) AS u;

-- INTERSECT: in A and B = "big spenders who also make large night payments"
SELECT account_id FROM transactions WHERE amount > 50000
INTERSECT
SELECT account_id FROM transactions WHERE HOUR(txn_time) < 5 AND amount > 10000
ORDER BY account_id;

-- EXCEPT: in A but not B = "big spenders with no large night payment"
SELECT COUNT(*) AS big_but_not_night FROM (
    SELECT account_id FROM transactions WHERE amount > 50000
    EXCEPT
    SELECT account_id FROM transactions WHERE HOUR(txn_time) < 5 AND amount > 10000
) AS e;

-- UNION to stack results of different shape into one report, with a label column
SELECT 'big amount' AS flagged_because, txn_id, account_id FROM transactions WHERE amount >= 90000
UNION
SELECT 'small hours', txn_id, account_id FROM transactions WHERE account_id = 1 AND HOUR(txn_time) < 5
ORDER BY txn_id;
