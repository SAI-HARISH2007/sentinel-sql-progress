-- Week 8 — FRAUD RULE 1 (high amount / z-score) for EVERY account at once
-- Week 5 did this for account 1 with variables. Now a derived table computes each account's average and
-- standard deviation, and the outer query joins every transaction to its own account's numbers.
-- HAVING COUNT(*) >= 5: with fewer than 5 transactions a standard deviation means nothing.
USE sentinel;

SELECT t.txn_id, t.account_id, t.amount,
       ROUND(s.avg_amount, 2) AS acct_avg,
       ROUND((t.amount - s.avg_amount) / s.sd_amount, 2) AS z_score
FROM transactions t
JOIN (SELECT account_id, AVG(amount) AS avg_amount, STDDEV_SAMP(amount) AS sd_amount
      FROM transactions
      GROUP BY account_id
      HAVING COUNT(*) >= 5) AS s ON s.account_id = t.account_id
WHERE (t.amount - s.avg_amount) / NULLIF(s.sd_amount, 0) > (SELECT threshold_value FROM rule_config WHERE rule_name = 'zscore')
ORDER BY z_score DESC
LIMIT 10;
-- Expected: txn 12052 (z about 6.97) is the top row.
-- Over the whole table 145 of 12,067 transactions (1.2 %) have z > 3, and almost all are ordinary purchases: amounts are
-- SKEWED (many small, few large) while a z-score assumes a bell curve. For an exponential distribution about 1.8 % of
-- values exceed mean + 3 standard deviations purely by chance. Know this for the viva: Rule 1 alone is a weak signal;
-- the project's strength is that Week 10 COMBINES six weak signals into one risk score.
