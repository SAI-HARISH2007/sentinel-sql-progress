-- Week 8 — ORDER BY, LIMIT, OFFSET
USE sentinel;

SELECT txn_id, amount, txn_time FROM transactions ORDER BY amount DESC LIMIT 5;                  -- largest first
SELECT txn_id, amount, txn_time FROM transactions ORDER BY txn_time DESC LIMIT 5;                -- newest first
SELECT txn_id, amount FROM transactions ORDER BY amount DESC LIMIT 5 OFFSET 5;                    -- "page 2" of the top list

-- Several sort keys: status A-Z, then biggest amount first inside each status
SELECT txn_id, status, amount FROM transactions WHERE account_id = 1 ORDER BY status ASC, amount DESC LIMIT 6;

-- Sort by an expression or an alias
SELECT account_id, ROUND(SUM(amount)) AS total_spent FROM transactions GROUP BY account_id ORDER BY total_spent DESC LIMIT 5;
SELECT user_id, full_name FROM users ORDER BY CHAR_LENGTH(full_name) DESC, full_name LIMIT 3;

-- NULLs sort first in ASC order in MySQL. Without ORDER BY, row order is NOT guaranteed, even if it looks stable.
