-- Week 5 — FRAUD RULE 5 (by hand): impossible travel, combining NUMBER and DATE functions
-- Persona "traveller": txn 12041 in Delhi at 10:00, txn 12042 in Chennai at 10:10 (same account).
-- Speed = distance / time. A passenger jet cruises at ~900 km/h, so anything faster is physically impossible.
USE sentinel;

-- Step 1: where and when was each transaction?   Step 2: where is that location on the map?
SELECT location_id, txn_time INTO @loc1, @t1 FROM transactions WHERE txn_id = 12041;
SELECT location_id, txn_time INTO @loc2, @t2 FROM transactions WHERE txn_id = 12042;
SELECT latitude, longitude INTO @lat1, @lon1 FROM locations WHERE location_id = @loc1;
SELECT latitude, longitude INTO @lat2, @lon2 FROM locations WHERE location_id = @loc2;

SET @a = POWER(SIN(RADIANS(@lat2 - @lat1) / 2), 2)
       + COS(RADIANS(@lat1)) * COS(RADIANS(@lat2)) * POWER(SIN(RADIANS(@lon2 - @lon1) / 2), 2);
SET @km    = 6371 * 2 * ATAN2(SQRT(@a), SQRT(1 - @a));
SET @hours = TIMESTAMPDIFF(SECOND, @t1, @t2) / 3600.0;

SELECT ROUND(@km, 1)          AS distance_km,
       ROUND(@hours * 60, 0)  AS minutes,
       ROUND(@km / @hours, 0) AS implied_speed_kmh,
       IF(@km / @hours > (SELECT threshold_value FROM rule_config WHERE rule_name = 'impossible_travel'),
          'IMPOSSIBLE TRAVEL', 'plausible') AS verdict;
-- Expected: ~1,768 km in 10 minutes = ~10,600 km/h -> IMPOSSIBLE TRAVEL
-- Week 7 does the same thing for ALL accounts at once with a self-join; Week 9 turns it into a view.
