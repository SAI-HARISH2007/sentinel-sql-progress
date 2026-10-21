-- Week 5 — NUMBER functions        mysql -uroot -p sentinel < queries/01_number_functions.sql
USE sentinel;

-- ROUND, CEIL, FLOOR, TRUNCATE, MOD, ABS, SQRT, POWER on real transaction amounts
SELECT txn_id,
       amount,
       ROUND(amount, -2)        AS round_to_hundred,
       CEIL(amount)             AS ceil_amt,
       FLOOR(amount)            AS floor_amt,
       TRUNCATE(amount, 0)      AS truncated,
       MOD(txn_id, 10)          AS txn_id_mod_10,
       ABS(amount - 5000)       AS distance_from_5000,
       ROUND(SQRT(amount), 2)   AS square_root,
       POWER(2, 10)             AS two_to_the_ten
FROM transactions
WHERE account_id = 1
ORDER BY txn_id
LIMIT 5;

-- FLOOR to build "buckets": which 10,000-rupee band is each persona transaction in?
SELECT txn_id, amount, FLOOR(amount / 10000) * 10000 AS bucket_start
FROM transactions
WHERE txn_id IN (12041, 12042, 12052);

-- GREATEST / LEAST / SIGN / PI / RADIANS (the pieces of the distance formula below)
SELECT GREATEST(10, 250, 40) AS biggest, LEAST(10, 250, 40) AS smallest, SIGN(-7) AS sign_of_minus_7,
       ROUND(PI(), 5) AS pi, ROUND(RADIANS(180), 5) AS radians_of_180;

-- Distance between two cities with the Haversine formula, using ONLY number functions.
-- (Week 10 wraps this in a stored function; Week 9 uses it inside a view.)
SELECT latitude, longitude INTO @lat1, @lon1 FROM locations WHERE city = 'Delhi';
SELECT latitude, longitude INTO @lat2, @lon2 FROM locations WHERE city = 'Chennai';
SET @a = POWER(SIN(RADIANS(@lat2 - @lat1) / 2), 2)
       + COS(RADIANS(@lat1)) * COS(RADIANS(@lat2)) * POWER(SIN(RADIANS(@lon2 - @lon1) / 2), 2);
SELECT ROUND(6371 * 2 * ATAN2(SQRT(@a), SQRT(1 - @a)), 1) AS delhi_to_chennai_km;   -- about 1,768 km
