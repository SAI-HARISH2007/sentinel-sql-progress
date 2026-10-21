-- =============================================================================
-- Week 10 — STORED FUNCTION
-- 10_haversine_function.sql — great-circle distance between two coordinates, as a reusable function
-- =============================================================================
-- Weeks 5, 7 and 9 each pasted the Haversine formula inline. A stored function gives it a name, so it is written ONCE.
--   function  : returns a single value and can be used inside SELECT, like ROUND() or HOUR()
--   procedure : is run with CALL, can return result sets, and can change data (next file)
-- DETERMINISTIC = same inputs always give the same output (lets MySQL cache and optimise); NO SQL = it reads no tables.

USE sentinel;

DROP FUNCTION IF EXISTS haversine_km;
DELIMITER //
CREATE FUNCTION haversine_km(lat1 DECIMAL(9,6), lon1 DECIMAL(9,6), lat2 DECIMAL(9,6), lon2 DECIMAL(9,6))
RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL
BEGIN
    DECLARE a DOUBLE;
    SET a = POWER(SIN(RADIANS(lat2 - lat1) / 2), 2)
          + COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * POWER(SIN(RADIANS(lon2 - lon1) / 2), 2);
    RETURN 2 * 6371 * ASIN(SQRT(LEAST(1, a)));       -- LEAST(1, a) guards against rounding pushing a just above 1
END //
DELIMITER ;

-- Refactor the Week 9 view to call the function instead of repeating the formula. Same results, shorter SQL.
-- CREATE OR REPLACE keeps the SELECT privileges already granted on the view.
CREATE OR REPLACE VIEW rule_impossible_travel AS
WITH with_previous AS (
    SELECT t.txn_id,
           t.account_id,
           t.txn_time,
           l.latitude  AS lat,
           l.longitude AS lon,
           LAG(l.latitude)  OVER w AS prev_lat,
           LAG(l.longitude) OVER w AS prev_lon,
           LAG(t.txn_time)  OVER w AS prev_time
    FROM transactions t
    JOIN locations l ON l.location_id = t.location_id
    WINDOW w AS (PARTITION BY t.account_id ORDER BY t.txn_time, t.txn_id)
),
with_distance AS (
    SELECT txn_id, account_id,
           haversine_km(prev_lat, prev_lon, lat, lon)          AS distance_km,
           TIMESTAMPDIFF(SECOND, prev_time, txn_time) / 3600.0 AS hours_apart
    FROM with_previous
    WHERE prev_time IS NOT NULL
)
SELECT wd.txn_id,
       wd.account_id,
       ROUND(wd.distance_km, 2)                    AS distance_km,
       ROUND(wd.hours_apart * 60, 1)               AS minutes_diff,
       ROUND(wd.distance_km / wd.hours_apart, 0)   AS implied_speed_kmh,
       rc.threshold_value                          AS max_speed_kmh
FROM with_distance wd
JOIN rule_config rc ON rc.rule_name = 'impossible_travel'
WHERE rc.enabled
  AND wd.hours_apart > 0
  AND wd.distance_km > 50
  AND wd.distance_km / wd.hours_apart > rc.threshold_value;
