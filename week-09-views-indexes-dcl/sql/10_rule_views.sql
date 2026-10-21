-- =============================================================================
-- Week 9 — VIEWS: the six fraud rules, saved as named, reusable queries
-- 10_rule_views.sql
-- =============================================================================
-- A view is a stored SELECT. It holds no data of its own; every time you query it, MySQL runs the SELECT.
-- Why use them here:
--   * each rule gets a NAME ("SELECT * FROM rule_new_device") instead of 20 lines pasted around
--   * the logic lives in ONE place, so fixing a rule fixes every report that uses it
--   * Week 9's roles can be allowed to read a view without being allowed to read the tables underneath
-- Every rule view returns one row per FLAGGED transaction, and reads its threshold from rule_config
-- (and respects rule_config.enabled), so tuning is an UPDATE.
--
-- Syntax used beyond the lab list: WITH (common table expression = a named subquery you can reuse inside one
-- statement) and LAG() (a window function = look at the previous row of the same group). Both are explained in README.md.

USE sentinel;

-- -----------------------------------------------------------------------------
-- Rule 1 — high amount (z-score).   Week 5 by hand, Week 8 for all accounts, now a view.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW rule_zscore AS
WITH account_stats AS (
    SELECT account_id,
           AVG(amount)         AS avg_amt,
           STDDEV_SAMP(amount) AS sd_amt
    FROM transactions
    GROUP BY account_id
    HAVING COUNT(*) >= 5
)
SELECT t.txn_id,
       t.account_id,
       t.amount,
       ROUND(s.avg_amt, 2) AS avg_amt,
       ROUND(s.sd_amt, 2)  AS stddev_amt,
       ROUND((t.amount - s.avg_amt) / s.sd_amt, 2) AS z_score,
       rc.threshold_value  AS threshold
FROM transactions t
JOIN account_stats s ON s.account_id = t.account_id
JOIN rule_config  rc ON rc.rule_name = 'zscore'
WHERE rc.enabled
  AND (t.amount - s.avg_amt) / NULLIF(s.sd_amt, 0) > rc.threshold_value;

-- -----------------------------------------------------------------------------
-- Rule 2 — off-hours.   Flag a transaction whose hour of day holds fewer than threshold (2 %) of the account's history.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW rule_off_hours AS
WITH hour_counts AS (
    SELECT account_id, HOUR(txn_time) AS hr, COUNT(*) AS hour_txns
    FROM transactions
    GROUP BY account_id, HOUR(txn_time)
),
totals AS (
    SELECT account_id, COUNT(*) AS total_txns
    FROM transactions
    GROUP BY account_id
)
SELECT t.txn_id,
       t.account_id,
       HOUR(t.txn_time) AS txn_hour,
       ROUND(100 * h.hour_txns / tt.total_txns, 2) AS hour_pct,
       rc.threshold_value * 100                    AS threshold_pct
FROM transactions t
JOIN hour_counts h  ON h.account_id = t.account_id AND h.hr = HOUR(t.txn_time)
JOIN totals      tt ON tt.account_id = t.account_id
JOIN rule_config rc ON rc.rule_name = 'off_hours'
WHERE rc.enabled
  AND h.hour_txns / tt.total_txns < rc.threshold_value;

-- -----------------------------------------------------------------------------
-- Rule 3 — new device.   The Week 7 anti-join (LEFT JOIN ... IS NULL).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW rule_new_device AS
SELECT t.txn_id,
       t.account_id,
       t.device_id,
       d.fingerprint_hash,
       d.device_type,
       d.os
FROM transactions t
JOIN devices d                ON d.device_id = t.device_id
JOIN rule_config rc           ON rc.rule_name = 'new_device'
LEFT JOIN account_devices ad  ON ad.account_id = t.account_id AND ad.device_id = t.device_id
WHERE rc.enabled
  AND ad.account_id IS NULL;

-- -----------------------------------------------------------------------------
-- Rule 4 — velocity.   The Week 7 self-join + Week 8 GROUP BY / HAVING.
-- Window length (minutes) and the limit both come from rule_config.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW rule_velocity AS
SELECT t1.txn_id,
       t1.account_id,
       t1.txn_time,
       COUNT(*)                                  AS txns_in_window,
       CAST(lim.threshold_value AS UNSIGNED)     AS velocity_limit,
       CAST(win.threshold_value AS UNSIGNED)     AS window_minutes
FROM transactions t1
JOIN rule_config lim ON lim.rule_name = 'velocity'
JOIN rule_config win ON win.rule_name = 'velocity_window'
JOIN transactions t2 ON t2.account_id = t1.account_id
                    AND t2.txn_time BETWEEN DATE_SUB(t1.txn_time, INTERVAL CAST(win.threshold_value AS UNSIGNED) MINUTE)
                                        AND t1.txn_time
WHERE lim.enabled
GROUP BY t1.txn_id, t1.account_id, t1.txn_time, lim.threshold_value, win.threshold_value
HAVING COUNT(*) > velocity_limit;      -- HAVING may use the alias defined in the SELECT list

-- -----------------------------------------------------------------------------
-- Rule 5 — impossible travel.   LAG() fetches the account's PREVIOUS transaction (location and time) on the same row.
-- The distance is the Haversine formula written inline (Week 5). Week 10 replaces this view so that it calls a stored
-- function, haversine_km(), instead of repeating the formula.
-- -----------------------------------------------------------------------------
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
           2 * 6371 * ASIN(SQRT(POWER(SIN(RADIANS(lat - prev_lat) / 2), 2)
               + COS(RADIANS(prev_lat)) * COS(RADIANS(lat)) * POWER(SIN(RADIANS(lon - prev_lon) / 2), 2))) AS distance_km,
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

-- -----------------------------------------------------------------------------
-- Rule 6 — merchant risk.   Week 8's GROUP BY / HAVING / subquery, now using the REAL alerts table.
-- Until alerts exist (Week 10) this view is empty, and that is correct: no alerts means no merchant stands out.
-- A merchant must also have at least `merchant_risk_min_alerts` (3) alerts: with a tiny platform average, ONE alert at a
-- merchant would otherwise make its alert rate several times the average and condemn all of its transactions.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW rule_merchant_risk AS
WITH merchant_stats AS (
    SELECT t.merchant_id, COUNT(*) AS total_txns, COUNT(a.alert_id) AS alert_count
    FROM transactions t
    LEFT JOIN alerts a ON a.txn_id = t.txn_id
    GROUP BY t.merchant_id
    HAVING COUNT(*) >= 3
),
platform AS (
    SELECT COUNT(a.alert_id) / COUNT(*) AS platform_rate
    FROM transactions t
    LEFT JOIN alerts a ON a.txn_id = t.txn_id
)
SELECT t.txn_id,
       t.account_id,
       m.merchant_id,
       m.merchant_name,
       ms.total_txns,
       ms.alert_count,
       ROUND(100 * ms.alert_count / ms.total_txns, 2)                AS merchant_alert_pct,
       ROUND(100 * p.platform_rate, 2)                               AS platform_alert_pct,
       ROUND((ms.alert_count / ms.total_txns) / p.platform_rate, 2)  AS risk_multiplier,
       rc.threshold_value                                            AS threshold
FROM transactions t
JOIN merchant_stats ms ON ms.merchant_id = t.merchant_id
JOIN merchants      m  ON m.merchant_id  = t.merchant_id
CROSS JOIN platform p
JOIN rule_config    rc ON rc.rule_name = 'merchant_risk'
JOIN rule_config    rm ON rm.rule_name = 'merchant_risk_min_alerts'
WHERE rc.enabled
  AND ms.alert_count >= rm.threshold_value          -- one stray alert must not condemn a merchant
  AND (ms.alert_count / ms.total_txns) / NULLIF(p.platform_rate, 0) > rc.threshold_value;

-- -----------------------------------------------------------------------------
-- Combined view — one row per suspicious transaction: how many rules fired, and why in plain English.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_transaction_risk AS
SELECT t.txn_id,
       t.account_id,
       t.amount,
       t.txn_time,
       (z.txn_id IS NOT NULL) + (oh.txn_id IS NOT NULL) + (nd.txn_id IS NOT NULL)
     + (v.txn_id IS NOT NULL) + (it.txn_id IS NOT NULL) + (mr.txn_id IS NOT NULL) AS risk_score,
       CONCAT_WS('; ',
           IF(z.txn_id  IS NOT NULL, CONCAT('High amount (z=', z.z_score, ')'), NULL),
           IF(oh.txn_id IS NOT NULL, CONCAT('Off-hours (', oh.txn_hour, ':00, only ', oh.hour_pct, '% of history)'), NULL),
           IF(nd.txn_id IS NOT NULL, CONCAT('New device (', LEFT(nd.fingerprint_hash, 8), '...)'), NULL),
           IF(v.txn_id  IS NOT NULL, CONCAT('Velocity spike (', v.txns_in_window, ' in ', v.window_minutes, ' min)'), NULL),
           IF(it.txn_id IS NOT NULL, CONCAT('Impossible travel (', it.distance_km, ' km in ', it.minutes_diff, ' min)'), NULL),
           IF(mr.txn_id IS NOT NULL, CONCAT('Merchant risk (', mr.risk_multiplier, 'x platform average)'), NULL)
       ) AS reasons
FROM transactions t
LEFT JOIN rule_zscore            z  ON z.txn_id  = t.txn_id
LEFT JOIN rule_off_hours         oh ON oh.txn_id = t.txn_id
LEFT JOIN rule_new_device        nd ON nd.txn_id = t.txn_id
LEFT JOIN rule_velocity          v  ON v.txn_id  = t.txn_id
LEFT JOIN rule_impossible_travel it ON it.txn_id = t.txn_id
LEFT JOIN rule_merchant_risk     mr ON mr.txn_id = t.txn_id
WHERE z.txn_id IS NOT NULL OR oh.txn_id IS NOT NULL OR nd.txn_id IS NOT NULL
   OR v.txn_id IS NOT NULL OR it.txn_id IS NOT NULL OR mr.txn_id IS NOT NULL;
