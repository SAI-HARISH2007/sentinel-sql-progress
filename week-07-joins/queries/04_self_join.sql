-- Week 7 — SELF JOIN: a table joined to itself (give it two aliases and pretend they are two tables)
USE sentinel;

-- Two different users who share the same first name
SELECT u1.user_id AS user_a, u2.user_id AS user_b, u1.full_name AS name_a, u2.full_name AS name_b
FROM users u1
JOIN users u2 ON SUBSTRING_INDEX(u1.full_name, ' ', 1) = SUBSTRING_INDEX(u2.full_name, ' ', 1)
             AND u1.user_id < u2.user_id        -- "<" so each pair appears once and nobody pairs with themselves
WHERE SUBSTRING_INDEX(u1.full_name, ' ', 1) = 'Tammy';

-- FRAUD RULE 4 (velocity), first half: pair every transaction t1 with the SAME account's later transactions
-- t2 that happened within 5 minutes after it. Week 8's GROUP BY / HAVING turns the pairs into a count.
-- Burst persona: account 1, 17 Aug 2026, 14:00 - 14:03.
SELECT t1.txn_id AS first_txn, t2.txn_id AS later_txn, t1.txn_time, t2.txn_time AS later_time,
       TIMESTAMPDIFF(SECOND, t1.txn_time, t2.txn_time) AS seconds_apart
FROM transactions t1
JOIN transactions t2
  ON  t2.account_id = t1.account_id
  AND t2.txn_id     > t1.txn_id
  AND t2.txn_time BETWEEN t1.txn_time AND DATE_ADD(t1.txn_time, INTERVAL 5 MINUTE)
WHERE t1.account_id = 1
  AND t1.txn_time >= '2026-08-17'
  AND t1.txn_time <  '2026-08-18'
ORDER BY t1.txn_id, t2.txn_id
LIMIT 12;
