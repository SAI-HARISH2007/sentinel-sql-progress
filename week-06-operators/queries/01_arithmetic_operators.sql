-- Week 6 — ARITHMETIC operators:  +  -  *  /  DIV  %(MOD)
USE sentinel;

SELECT txn_id,
       amount,
       amount * 0.18                AS gst_18_percent,
       amount + amount * 0.18       AS amount_with_gst,
       amount / 3                   AS divided_by_3,
       amount DIV 1000              AS whole_thousands,   -- integer division: drops the fraction
       amount % 1000                AS remainder_after_thousands,
       -amount                      AS negated
FROM transactions
WHERE txn_id IN (12041, 12042, 12052);

-- Arithmetic across columns of one row: a month of interest at 4 % a year on each savings balance
SELECT account_id, balance, ROUND(balance * 0.04 / 12, 2) AS one_month_interest
FROM accounts
WHERE account_type = 'savings'
ORDER BY balance DESC
LIMIT 3;

-- Operator precedence: * and / before + and -.   Parentheses win.
SELECT 2 + 3 * 4 AS without_brackets, (2 + 3) * 4 AS with_brackets;

-- Division by zero gives NULL in MySQL (not an error): this is why the rules use NULLIF(x, 0) to be explicit
SELECT 10 / 0 AS ten_over_zero, 10 / NULLIF(0, 0) AS explicit_null;
