-- Week 8 assertions. Every row must say PASS.
USE sentinel;

SELECT 'behaviour_baselines has one row per account (597)',
       IF((SELECT COUNT(*) FROM behaviour_baselines) = 597, 'PASS', 'FAIL');
SELECT 'account 1 baseline: avg 5980.49, 11 distinct hours, 3 cities',
       IF((SELECT CONCAT(avg_amount, '/', JSON_LENGTH(peak_hours_json), '/', JSON_LENGTH(typical_cities_json)) FROM behaviour_baselines WHERE account_id = 1) = '5980.49/11/3', 'PASS', 'FAIL');

SELECT 'rule 1 (all accounts): 145 transactions exceed z=3 and 12052 is one of them',
       IF((SELECT COUNT(*) FROM transactions t JOIN (SELECT account_id, AVG(amount) a, STDDEV_SAMP(amount) s FROM transactions GROUP BY account_id HAVING COUNT(*) >= 5) x ON x.account_id = t.account_id
           WHERE (t.amount - x.a) / NULLIF(x.s, 0) > 3) = 145
      AND (SELECT COUNT(*) FROM transactions t JOIN (SELECT account_id, AVG(amount) a, STDDEV_SAMP(amount) s FROM transactions GROUP BY account_id HAVING COUNT(*) >= 5) x ON x.account_id = t.account_id
           WHERE t.txn_id = 12052 AND (t.amount - x.a) / NULLIF(x.s, 0) > 3) = 1, 'PASS', 'FAIL');

SELECT 'rule 2 (all accounts): 12043 (02:30) is off-hours for account 1',
       IF((SELECT COUNT(*) FROM transactions t
           JOIN (SELECT account_id, HOUR(txn_time) hr, COUNT(*) n FROM transactions GROUP BY account_id, HOUR(txn_time)) h ON h.account_id = t.account_id AND h.hr = HOUR(t.txn_time)
           JOIN (SELECT account_id, COUNT(*) total FROM transactions GROUP BY account_id) a ON a.account_id = t.account_id
           WHERE t.txn_id = 12043 AND h.n / a.total < 0.02) = 1, 'PASS', 'FAIL');

SELECT 'rule 4: velocity > 5 in 5 minutes flags exactly 3 transactions (12049, 12050, 12051)',
       IF((SELECT GROUP_CONCAT(txn_id ORDER BY txn_id) FROM (
              SELECT t1.txn_id FROM transactions t1
              JOIN transactions t2 ON t2.account_id = t1.account_id AND t2.txn_time BETWEEN DATE_SUB(t1.txn_time, INTERVAL 5 MINUTE) AND t1.txn_time
              GROUP BY t1.txn_id HAVING COUNT(*) > 5) v) = '12049,12050,12051', 'PASS', 'FAIL');

SELECT 'rule 6 stand-in: merchant 50 is the highest-risk merchant (5 merchants exceed 2x platform rate)',
       IF((SELECT COUNT(*) FROM (SELECT merchant_id FROM transactions GROUP BY merchant_id
              HAVING COUNT(*) >= 3 AND (SUM(amount > 10000) / COUNT(*)) / (SELECT SUM(amount > 10000) / COUNT(*) FROM transactions) > 2) z) = 5
      AND (SELECT merchant_id FROM transactions GROUP BY merchant_id ORDER BY SUM(amount > 10000) / COUNT(*) DESC LIMIT 1) = 50, 'PASS', 'FAIL');

SELECT 'subquery: 8 accounts have a payment over 50,000',
       IF((SELECT COUNT(*) FROM accounts a WHERE EXISTS (SELECT 1 FROM transactions t WHERE t.account_id = a.account_id AND t.amount > 50000)) = 8, 'PASS', 'FAIL');
