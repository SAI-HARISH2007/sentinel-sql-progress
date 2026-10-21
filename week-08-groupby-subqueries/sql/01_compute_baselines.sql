-- =============================================================================
-- Week 8 — GROUP BY + subqueries, as permanent project data
-- 01_compute_baselines.sql — fill behaviour_baselines: one row per account summarising its normal behaviour
-- =============================================================================
-- INSERT ... SELECT with three derived tables (subqueries in FROM), each built with GROUP BY:
--   s : average and standard deviation of the account's amounts        (the numbers Rule 1 compares against)
--   h : the set of hours of day the account has transacted in          (the idea behind Rule 2)
--   c : the set of cities the account has transacted in                (context for Rule 5)
-- JSON_ARRAYAGG packs a group's values into one JSON array. The DISTINCT is done in an inner subquery because
-- MySQL's JSON_ARRAYAGG does not accept the DISTINCT keyword.
--
-- Week 10 wraps exactly this statement in a nightly EVENT so the baselines refresh themselves.
-- Safe to re-run: it empties the table first.

USE sentinel;

DELETE FROM behaviour_baselines;

INSERT INTO behaviour_baselines (account_id, avg_amount, stddev_amount, peak_hours_json, typical_cities_json)
SELECT s.account_id,
       ROUND(s.avg_amount, 2),
       ROUND(s.sd_amount, 2),
       h.hours,
       c.cities
FROM (SELECT account_id, AVG(amount) AS avg_amount, STDDEV_SAMP(amount) AS sd_amount
      FROM transactions
      GROUP BY account_id) AS s
JOIN (SELECT account_id, JSON_ARRAYAGG(hr) AS hours
      FROM (SELECT DISTINCT account_id, HOUR(txn_time) AS hr FROM transactions) AS x
      GROUP BY account_id) AS h ON h.account_id = s.account_id
JOIN (SELECT account_id, JSON_ARRAYAGG(city) AS cities
      FROM (SELECT DISTINCT t.account_id, l.city
            FROM transactions t JOIN locations l ON l.location_id = t.location_id) AS y
      GROUP BY account_id) AS c ON c.account_id = s.account_id;
