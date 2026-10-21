-- Week 5 — FRAUD RULE 1: high amount (z-score), worked by hand for ONE account
-- z = (amount - average) / standard deviation.  z > 3 means "more than 3 standard deviations above this account's normal".
-- Aggregate functions give the average and deviation; user variables carry them to the next statement.
-- (Doing it for ALL accounts at once needs GROUP BY and subqueries: Week 8.)
USE sentinel;

SELECT AVG(amount), STDDEV_SAMP(amount) INTO @avg_amt, @sd_amt FROM transactions WHERE account_id = 1;
SELECT ROUND(@avg_amt, 2) AS account1_average, ROUND(@sd_amt, 2) AS account1_stddev;

SELECT txn_id,
       amount,
       ROUND((amount - @avg_amt) / @sd_amt, 2) AS z_score,
       CONCAT('High amount (z=', ROUND((amount - @avg_amt) / @sd_amt, 1), ')') AS reason
FROM transactions
WHERE account_id = 1
  AND (amount - @avg_amt) / @sd_amt > (SELECT threshold_value FROM rule_config WHERE rule_name = 'zscore')
ORDER BY z_score DESC;
-- Expected: exactly one row, txn 12052 (the 95,000 payment), z about 6.97
