-- Week 6 — COMPARISON operators:  =  <>  !=  <  >  <=  >=  <=>
USE sentinel;

SELECT COUNT(*) AS eq_failed         FROM transactions WHERE status =  'failed';
SELECT COUNT(*) AS not_success       FROM transactions WHERE status <> 'success';       -- != is the same
SELECT COUNT(*) AS over_50000        FROM transactions WHERE amount >  50000;
SELECT COUNT(*) AS at_least_50000    FROM transactions WHERE amount >= 50000;
SELECT COUNT(*) AS under_100         FROM transactions WHERE amount <  100;
SELECT COUNT(*) AS up_to_100         FROM transactions WHERE amount <= 100;

-- The NULL trap: nothing is ever "= NULL". Use IS NULL, or the NULL-safe equality <=>.
SELECT COUNT(*) AS wrong_equals_null FROM transactions WHERE metadata_json = NULL;    -- 0, always
SELECT COUNT(*) AS right_is_null     FROM transactions WHERE metadata_json IS NULL;   -- every row
SELECT NULL = NULL AS plain_equals, NULL <=> NULL AS null_safe_equals, 1 <=> 1 AS one_equals_one;

-- Comparing strings and dates works too
SELECT COUNT(*) AS in_august FROM transactions WHERE txn_time >= '2026-08-01' AND txn_time < '2026-09-01';
SELECT merchant_name FROM merchants WHERE merchant_name < 'B' ORDER BY merchant_name;
