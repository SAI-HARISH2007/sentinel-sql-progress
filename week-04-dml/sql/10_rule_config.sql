-- =============================================================================
-- Week 4 — DML: INSERT
-- 10_rule_config.sql — the detector's tunable thresholds, as data not code
-- =============================================================================
-- Every fraud rule reads its threshold from this table. Changing how strict the detector is
-- is therefore an UPDATE (see demo/dml_tour.sql), never an edit to a procedure.

USE sentinel;

INSERT INTO rule_config (rule_name, threshold_value, parameters_json) VALUES
    ('zscore',            3.0000,   '{"description": "Z-score above which an amount is anomalous"}'),
    ('off_hours',         0.0200,   '{"description": "Flag if the account has fewer than 2% of its transactions in this hour"}'),
    ('new_device',        1.0000,   '{"description": "Flag if the device was never seen on this account"}'),
    ('velocity',          5.0000,   '{"description": "Max transactions allowed inside the velocity window"}'),
    ('velocity_window',   5.0000,   '{"description": "Velocity window length in minutes"}'),
    ('impossible_travel', 900.0000, '{"description": "Max plausible speed in km/h between two transactions"}'),
    ('merchant_risk',     2.0000,   '{"description": "Flag if a merchant alert rate is this many times the platform average"}'),
    ('merchant_risk_min_alerts', 3.0000, '{"description": "A merchant needs at least this many alerts before it can be called risky (one alert proves nothing)"}');
