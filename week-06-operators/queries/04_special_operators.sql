-- Week 6 — SPECIAL operators:  BETWEEN  IN  NOT IN  LIKE  IS NULL  REGEXP
USE sentinel;

-- BETWEEN is inclusive at both ends
SELECT txn_id, amount FROM transactions WHERE amount BETWEEN 90000 AND 100000;
-- All persona activity falls in this window
SELECT COUNT(*) AS txns_15_to_20_aug FROM transactions WHERE txn_time BETWEEN '2026-08-15 00:00:00' AND '2026-08-20 23:59:59';

-- IN / NOT IN  (a tidy way to write several ORs)
SELECT status, COUNT(*) AS n FROM transactions WHERE status IN ('failed', 'pending') GROUP BY status;
SELECT COUNT(*) AS metros_only FROM locations WHERE city IN ('Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Hyderabad', 'Kolkata');
SELECT COUNT(*) AS non_metro    FROM locations WHERE city NOT IN ('Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Hyderabad', 'Kolkata');

-- LIKE:  % = any number of characters,  _ = exactly one character
SELECT user_id, full_name FROM users WHERE full_name LIKE 'Tammy%';
SELECT user_id, phone     FROM users WHERE phone LIKE '+9170%' LIMIT 3;
SELECT user_id, email     FROM users WHERE email LIKE 'user1_@example.com';        -- user10 .. user19

-- IS NULL / IS NOT NULL
SELECT COUNT(*) AS never_reviewed FROM alerts WHERE reviewed_at IS NULL;          -- 0 until Week 10 creates alerts
SELECT COUNT(*) AS has_phone      FROM users  WHERE phone IS NOT NULL;

-- REGEXP: full regular expressions (MySQL's extension)
SELECT user_id, phone FROM users WHERE phone REGEXP '^\\+91[89][0-9]{9}$' LIMIT 3;     -- Indian mobile starting 8 or 9
SELECT DISTINCT os FROM devices WHERE os REGEXP '^(Android|iOS)';
