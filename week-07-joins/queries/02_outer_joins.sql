-- Week 7 — OUTER JOINs: keep rows that have NO match on the other side (the gaps show up as NULL)
--   LEFT JOIN  keeps every row of the left table      RIGHT JOIN keeps every row of the right table
--   MySQL has no FULL OUTER JOIN: emulate it with LEFT JOIN  UNION  RIGHT JOIN.
USE sentinel;

-- Which accounts have NEVER logged in?  LEFT JOIN, then keep the rows where the right side is NULL.
-- This "anti-join" pattern answers every "which X has no Y" question.
SELECT a.account_id, a.account_type, a.balance
FROM accounts a
LEFT JOIN login_history lh ON lh.account_id = a.account_id
WHERE lh.login_id IS NULL
ORDER BY a.account_id
LIMIT 10;

-- Same pattern, different answer: devices never used in any transaction -> none (every device appears at least once)
SELECT COUNT(*) AS devices_never_used
FROM devices d LEFT JOIN transactions t ON t.device_id = d.device_id
WHERE t.txn_id IS NULL;

-- How many accounts have never logged in?
SELECT COUNT(*) AS accounts_without_login
FROM accounts a LEFT JOIN login_history lh ON lh.account_id = a.account_id
WHERE lh.login_id IS NULL;

-- RIGHT JOIN is a LEFT JOIN with the tables swapped. These two return the same rows:
SELECT COUNT(*) AS via_right FROM login_history lh RIGHT JOIN accounts a ON a.account_id = lh.account_id WHERE lh.login_id IS NULL;
SELECT COUNT(*) AS via_left  FROM accounts a      LEFT  JOIN login_history lh ON lh.account_id = a.account_id WHERE lh.login_id IS NULL;

-- FULL OUTER JOIN emulation: everything from both sides, matched where possible
SELECT COUNT(*) AS full_outer_rows FROM (
    SELECT d.device_id AS d_id, t.txn_id FROM devices d LEFT  JOIN transactions t ON t.device_id = d.device_id
    UNION
    SELECT d.device_id,         t.txn_id FROM devices d RIGHT JOIN transactions t ON t.device_id = d.device_id
) f;
