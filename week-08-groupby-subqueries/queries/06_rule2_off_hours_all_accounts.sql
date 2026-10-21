-- Week 8 — FRAUD RULE 2 (off-hours) for EVERY account at once
-- For each (account, hour): what share of that account's history happened in that hour?
-- A transaction in an hour holding < 2 % of the account's history is "off-hours".
-- Caveat to remember: with few transactions every hour is rare. An account with 20 transactions has hours at 5 % each,
-- so the rule can only fire for accounts with more than 50 transactions (1 / 50 = 2 %).
USE sentinel;

SELECT t.txn_id, t.account_id, HOUR(t.txn_time) AS hr, ROUND(100 * h.hour_txns / a.total_txns, 2) AS hour_pct_of_history
FROM transactions t
JOIN (SELECT account_id, HOUR(txn_time) AS hr, COUNT(*) AS hour_txns
      FROM transactions GROUP BY account_id, HOUR(txn_time)) AS h
     ON h.account_id = t.account_id AND h.hr = HOUR(t.txn_time)
JOIN (SELECT account_id, COUNT(*) AS total_txns FROM transactions GROUP BY account_id) AS a
     ON a.account_id = t.account_id
WHERE h.hour_txns / a.total_txns < (SELECT threshold_value FROM rule_config WHERE rule_name = 'off_hours')
ORDER BY t.account_id, t.txn_time;
-- Expected: txn 12043 (02:30, 1 of 52 = 1.92 %) is in the output. Account 1 also gets a few "off-hours" hits at other
-- hours that happen to contain exactly one of its 52 transactions - a built-in weakness of a % rule on small history.
