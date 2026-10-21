-- Week 5 — DATE and TIME functions
USE sentinel;

SELECT NOW() AS right_now, CURDATE() AS today, CURTIME() AS clock_time;

-- Pulling a transaction's timestamp apart. This is exactly what Rule 2 (off-hours) needs: the HOUR.
SELECT txn_id, txn_time,
       DATE(txn_time)       AS txn_date,
       HOUR(txn_time)       AS txn_hour,
       MINUTE(txn_time)     AS txn_minute,
       DAYNAME(txn_time)    AS weekday,
       MONTHNAME(txn_time)  AS month_name,
       YEAR(txn_time)       AS txn_year,
       DATE_FORMAT(txn_time, '%d %b %Y, %h:%i %p') AS pretty
FROM transactions
WHERE txn_id IN (12041, 12043);

-- Date arithmetic
SELECT DATE_ADD('2026-08-15', INTERVAL 10 DAY)  AS plus_10_days,
       DATE_SUB('2026-08-15', INTERVAL 1 MONTH) AS minus_1_month,
       DATEDIFF('2026-09-01', '2026-08-15')      AS days_between,
       LAST_DAY('2026-02-10')                    AS end_of_feb,
       EXTRACT(HOUR FROM '2026-08-16 02:30:00')  AS extracted_hour;

-- Time between the two "traveller" transactions (Delhi, then Chennai). Rule 5 needs this number.
SELECT txn_time INTO @t1 FROM transactions WHERE txn_id = 12041;
SELECT txn_time INTO @t2 FROM transactions WHERE txn_id = 12042;
SELECT @t1 AS first_txn, @t2 AS second_txn,
       TIMESTAMPDIFF(MINUTE, @t1, @t2) AS minutes_apart,
       TIMESTAMPDIFF(SECOND, @t1, @t2) / 3600.0 AS hours_apart;

-- Age of each account holder from date_of_birth
SELECT user_id, date_of_birth, TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age
FROM users
WHERE user_id <= 5;
