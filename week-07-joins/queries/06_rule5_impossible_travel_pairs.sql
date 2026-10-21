-- Week 7 — FRAUD RULE 5 for every account at once, by self-joining transactions
-- Pair each transaction t1 with LATER transactions t2 of the SAME account within 60 minutes, look up both
-- locations, compute the great-circle distance, and keep pairs whose implied speed is over the limit.
--   distance = 2 * R * ASIN( SQRT( a ) )      (Haversine; R = 6371 km)
-- HAVING is used here only so we can filter on the aliases distance_km / minutes defined in the SELECT list
-- (WHERE cannot see them). Week 8 explains HAVING properly.
-- Week 9 reformulates this with the window function LAG, which looks only at the immediately previous
-- transaction; the self-join is stricter because it compares against every transaction in the last hour.
USE sentinel;

SELECT t1.account_id,
       t1.txn_id AS from_txn, l1.city AS from_city,
       t2.txn_id AS to_txn,   l2.city AS to_city,
       ROUND(TIMESTAMPDIFF(SECOND, t1.txn_time, t2.txn_time) / 60, 1) AS minutes,
       ROUND(2 * 6371 * ASIN(SQRT(
             POWER(SIN(RADIANS(l2.latitude - l1.latitude) / 2), 2)
           + COS(RADIANS(l1.latitude)) * COS(RADIANS(l2.latitude))
             * POWER(SIN(RADIANS(l2.longitude - l1.longitude) / 2), 2))), 0) AS distance_km
FROM transactions t1
JOIN transactions t2 ON t2.account_id = t1.account_id
                    AND t2.txn_time  >  t1.txn_time
                    AND t2.txn_time <= DATE_ADD(t1.txn_time, INTERVAL 60 MINUTE)
JOIN locations l1 ON l1.location_id = t1.location_id
JOIN locations l2 ON l2.location_id = t2.location_id
HAVING distance_km > 50
   AND distance_km / (minutes / 60) > 900          -- implied speed in km/h
ORDER BY t1.account_id, t1.txn_id;
-- Expected: 33 rows. Row 1 is the traveller persona (account 1, Delhi -> Chennai in 10 minutes).
-- The other 32 are NOISE: the seed generator gives every transaction a RANDOM city, so some accounts "teleport"
-- by chance. Real data would have home cities. Remember this when you explain false positives in the viva.
