-- =============================================================================
-- Week 10 — PROCEDURE WITH TRANSACTION CONTROL + a scheduled EVENT
-- 40_baseline_refresh_and_event.sql
-- =============================================================================
-- refresh_behaviour_baselines() is Week 8's INSERT ... SELECT wrapped in a transaction: either the whole table is
-- rebuilt or nothing changes. The EXIT HANDLER turns ANY SQL error into ROLLBACK + re-raise the error.
-- evt_refresh_baselines calls it every night at 02:30 (needs the event scheduler: --event-scheduler=ON in docker-compose.yml).

USE sentinel;

DROP PROCEDURE IF EXISTS refresh_behaviour_baselines;
DELIMITER //
CREATE PROCEDURE refresh_behaviour_baselines()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    DELETE FROM behaviour_baselines;

    INSERT INTO behaviour_baselines (account_id, avg_amount, stddev_amount, peak_hours_json, typical_cities_json)
    SELECT s.account_id,
           ROUND(s.avg_amount, 2),
           ROUND(s.sd_amount, 2),
           h.hours,
           c.cities
    FROM (SELECT account_id, AVG(amount) AS avg_amount, STDDEV_SAMP(amount) AS sd_amount
          FROM transactions GROUP BY account_id) AS s
    JOIN (SELECT account_id, JSON_ARRAYAGG(hr) AS hours
          FROM (SELECT DISTINCT account_id, HOUR(txn_time) AS hr FROM transactions) AS x
          GROUP BY account_id) AS h ON h.account_id = s.account_id
    JOIN (SELECT account_id, JSON_ARRAYAGG(city) AS cities
          FROM (SELECT DISTINCT t.account_id, l.city
                FROM transactions t JOIN locations l ON l.location_id = t.location_id) AS y
          GROUP BY account_id) AS c ON c.account_id = s.account_id;

    COMMIT;
END //
DELIMITER ;

DROP EVENT IF EXISTS evt_refresh_baselines;
DELIMITER //
CREATE EVENT evt_refresh_baselines
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURRENT_DATE + INTERVAL 1 DAY, '02:30:00'))
DO
BEGIN
    CALL refresh_behaviour_baselines();
END //
DELIMITER ;
