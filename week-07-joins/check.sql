-- Week 7 assertions. Every row must say PASS.
USE sentinel;
SELECT 'inner join: the 95,000 payment belongs to Tammy Allison at merchant Cline-Ayala in Mumbai',
       IF((SELECT CONCAT(u.full_name, '/', m.merchant_name, '/', l.city)
           FROM transactions t JOIN accounts a ON a.account_id = t.account_id JOIN users u ON u.user_id = a.user_id
           JOIN merchants m ON m.merchant_id = t.merchant_id JOIN locations l ON l.location_id = t.location_id
           WHERE t.txn_id = 12052) = 'Tammy Allison/Cline-Ayala/Mumbai', 'PASS', 'FAIL');

SELECT 'outer join: 434 accounts have never logged in',
       IF((SELECT COUNT(*) FROM accounts a LEFT JOIN login_history lh ON lh.account_id = a.account_id WHERE lh.login_id IS NULL) = 434, 'PASS', 'FAIL');

SELECT 'natural join: merchants x locations matches nothing (3 shared column names)',
       IF((SELECT COUNT(*) FROM merchants NATURAL JOIN locations) = 0, 'PASS', 'FAIL');

SELECT 'self join (rule 4 half): the burst persona makes 28 pairs within 5 minutes (8 txns -> C(8,2))',
       IF((SELECT COUNT(*) FROM transactions t1 JOIN transactions t2
             ON t2.account_id = t1.account_id AND t2.txn_id > t1.txn_id
            AND t2.txn_time BETWEEN t1.txn_time AND DATE_ADD(t1.txn_time, INTERVAL 5 MINUTE)
           WHERE t1.account_id = 1 AND t1.txn_time >= '2026-08-17' AND t1.txn_time < '2026-08-18') = 28, 'PASS', 'FAIL');

SELECT 'rule 3: 16 transactions came from a device unknown to the account, including 12052 (device 999)',
       IF((SELECT COUNT(*) FROM transactions t LEFT JOIN account_devices ad ON ad.account_id = t.account_id AND ad.device_id = t.device_id WHERE ad.account_id IS NULL) = 16
      AND (SELECT COUNT(*) FROM transactions t LEFT JOIN account_devices ad ON ad.account_id = t.account_id AND ad.device_id = t.device_id WHERE ad.account_id IS NULL AND t.txn_id = 12052) = 1, 'PASS', 'FAIL');

SELECT 'rule 5: 33 impossible-travel pairs, and the traveller persona (12041 -> 12042) is one of them',
       IF((SELECT COUNT(*) FROM (
             SELECT t1.txn_id AS a_id, t2.txn_id AS b_id,
                    2 * 6371 * ASIN(SQRT(POWER(SIN(RADIANS(l2.latitude - l1.latitude) / 2), 2)
                      + COS(RADIANS(l1.latitude)) * COS(RADIANS(l2.latitude)) * POWER(SIN(RADIANS(l2.longitude - l1.longitude) / 2), 2))) AS dist,
                    TIMESTAMPDIFF(SECOND, t1.txn_time, t2.txn_time) / 3600.0 AS hrs
             FROM transactions t1
             JOIN transactions t2 ON t2.account_id = t1.account_id AND t2.txn_time > t1.txn_time AND t2.txn_time <= DATE_ADD(t1.txn_time, INTERVAL 60 MINUTE)
             JOIN locations l1 ON l1.location_id = t1.location_id JOIN locations l2 ON l2.location_id = t2.location_id) p
           WHERE dist > 50 AND dist / hrs > 900) = 33
      AND (SELECT COUNT(*) FROM (
             SELECT t1.txn_id AS a_id, t2.txn_id AS b_id
             FROM transactions t1 JOIN transactions t2 ON t2.account_id = t1.account_id AND t2.txn_id = 12042 AND t1.txn_id = 12041) x) = 1, 'PASS', 'FAIL');
