-- Week 6 assertions. Every row must say PASS.
USE sentinel;
SELECT '8 payments over 50,000',  IF((SELECT COUNT(*) FROM transactions WHERE amount > 50000) = 8, 'PASS', 'FAIL');
SELECT 'AND/OR precedence: with brackets 148, without 1300',
       IF((SELECT COUNT(*) FROM transactions WHERE amount > 5000 AND (status = 'failed' OR status = 'pending')) = 148
      AND (SELECT COUNT(*) FROM transactions WHERE amount > 5000 AND status = 'failed' OR status = 'pending') = 1300, 'PASS', 'FAIL');
SELECT 'INTERSECT: only account 20 is both a big spender and a large night payer',
       IF((SELECT COUNT(*) FROM (
              SELECT account_id FROM transactions WHERE amount > 50000
              INTERSECT
              SELECT account_id FROM transactions WHERE HOUR(txn_time) < 5 AND amount > 10000) i) = 1
      AND (SELECT account_id FROM (
              SELECT account_id FROM transactions WHERE amount > 50000
              INTERSECT
              SELECT account_id FROM transactions WHERE HOUR(txn_time) < 5 AND amount > 10000) i) = 20, 'PASS', 'FAIL');
SELECT 'EXCEPT: 7 big spenders without a large night payment',
       IF((SELECT COUNT(*) FROM (
              SELECT account_id FROM transactions WHERE amount > 50000
              EXCEPT
              SELECT account_id FROM transactions WHERE HOUR(txn_time) < 5 AND amount > 10000) e) = 7, 'PASS', 'FAIL');
SELECT 'first-cut screen catches 216 transactions (far more than the 27 planted ones: false positives!)',
       IF((SELECT COUNT(*) FROM transactions WHERE amount >= 50000 OR (HOUR(txn_time) BETWEEN 0 AND 4 AND amount > 5000) OR device_id = 999) = 216, 'PASS', 'FAIL');
SELECT '= NULL never matches, IS NULL does',
       IF((SELECT COUNT(*) FROM transactions WHERE metadata_json = NULL) = 0
      AND (SELECT COUNT(*) FROM transactions WHERE metadata_json IS NULL) = 12067, 'PASS', 'FAIL');
