-- Week 5 assertions. Every row must say PASS.   (Week 5 adds no tables; it adds queries. These assertions run the
-- core logic of the queries and check the answers, so a broken data set or a wrong formula is caught.)
USE sentinel;

-- Rule 1 by hand: account 1's only z-score outlier is the 95,000 payment
SELECT AVG(amount), STDDEV_SAMP(amount) INTO @avg_amt, @sd_amt FROM transactions WHERE account_id = 1;
SELECT 'rule 1: exactly one z>3 outlier on account 1, and it is txn 12052',
       IF((SELECT COUNT(*) FROM transactions WHERE account_id = 1 AND (amount - @avg_amt) / @sd_amt > 3) = 1
      AND (SELECT COUNT(*) FROM transactions WHERE txn_id = 12052 AND (amount - @avg_amt) / @sd_amt > 3) = 1, 'PASS', 'FAIL');

-- Rule 2 preview: account 1's only small-hours transaction is the 02:30 persona
SELECT 'rule 2: only txn 12043 falls between 00:00 and 04:59 on account 1',
       IF((SELECT COUNT(*) FROM transactions WHERE account_id = 1 AND HOUR(txn_time) BETWEEN 0 AND 4) = 1
      AND (SELECT COUNT(*) FROM transactions WHERE txn_id = 12043 AND HOUR(txn_time) = 2) = 1, 'PASS', 'FAIL');

-- Rule 5 by hand: Delhi -> Chennai in 10 minutes
SELECT location_id, txn_time INTO @loc1, @t1 FROM transactions WHERE txn_id = 12041;
SELECT location_id, txn_time INTO @loc2, @t2 FROM transactions WHERE txn_id = 12042;
SELECT latitude, longitude INTO @lat1, @lon1 FROM locations WHERE location_id = @loc1;
SELECT latitude, longitude INTO @lat2, @lon2 FROM locations WHERE location_id = @loc2;
SET @a = POWER(SIN(RADIANS(@lat2 - @lat1) / 2), 2) + COS(RADIANS(@lat1)) * COS(RADIANS(@lat2)) * POWER(SIN(RADIANS(@lon2 - @lon1) / 2), 2);
SET @km = 6371 * 2 * ATAN2(SQRT(@a), SQRT(1 - @a));
SELECT 'rule 5: Delhi-Chennai is between 1700 and 1800 km',   IF(@km BETWEEN 1700 AND 1800, 'PASS', 'FAIL');
SELECT 'rule 5: implied speed is far above 900 km/h',        IF(@km / (TIMESTAMPDIFF(SECOND, @t1, @t2) / 3600.0) > 900, 'PASS', 'FAIL');

SELECT 'masked phone keeps only the last 4 digits',
       IF((SELECT CONCAT('******', RIGHT(phone, 4)) FROM users WHERE user_id = 1) REGEXP '^\\*{6}[0-9]{4}$', 'PASS', 'FAIL');
