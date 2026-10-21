-- Week 8 — FRAUD RULE 6 (merchant risk): how much worse than average is this merchant's alert rate?
-- The real rule compares each merchant's share of ALERTED transactions with the platform's. The alerts table is
-- still empty (the trigger arrives in Week 10), so today we use a STAND-IN for "alerted": a payment over 10,000.
-- Week 9 turns the real rule into a view; after the Week 10 back-fill it starts returning rows.
USE sentinel;

SELECT m.merchant_id, m.merchant_name,
       COUNT(*)                                        AS txns,
       SUM(t.amount > 10000)                           AS flagged,
       ROUND(100 * SUM(t.amount > 10000) / COUNT(*), 2) AS merchant_rate_pct,
       ROUND(100 * (SELECT SUM(amount > 10000) / COUNT(*) FROM transactions), 2) AS platform_rate_pct,
       ROUND((SUM(t.amount > 10000) / COUNT(*)) / (SELECT SUM(amount > 10000) / COUNT(*) FROM transactions), 1) AS times_platform
FROM merchants m
JOIN transactions t ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_id, m.merchant_name
HAVING COUNT(*) >= 3
   AND (SUM(t.amount > 10000) / COUNT(*)) / (SELECT SUM(amount > 10000) / COUNT(*) FROM transactions)
       > (SELECT threshold_value FROM rule_config WHERE rule_name = 'merchant_risk')
ORDER BY times_platform DESC;
-- Expected: merchant 50 at the top (15 planted bad-merchant payments of 18,000-80,000 on top of its normal traffic).
-- SUM(condition) works because a true comparison is 1 and a false one is 0 in MySQL.
