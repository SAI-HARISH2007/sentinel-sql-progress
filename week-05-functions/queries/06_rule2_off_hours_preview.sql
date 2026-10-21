-- Week 5 — FRAUD RULE 2 (preview): off-hours, using the HOUR() date function
-- The full rule ("this hour holds < 2% of the account's history") needs GROUP BY: Week 8.
-- Today's version is simpler: list account 1's transactions between midnight and 5 a.m.
USE sentinel;

SELECT txn_id, txn_time, HOUR(txn_time) AS hr, amount
FROM transactions
WHERE account_id = 1
  AND HOUR(txn_time) BETWEEN 0 AND 4;
-- Expected: exactly one row, txn 12043 at 02:30 on 2026-08-16 (account 1 otherwise shops 9 a.m. - 6 p.m.)
