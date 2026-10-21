-- =============================================================================
-- Week 2 — DDL: CREATE
-- 01_create_tables.sql — the 13 tables, columns and data types ONLY
-- =============================================================================
-- Deliberately bare: no PRIMARY KEY, no FOREIGN KEY, no NOT NULL, no DEFAULT, no CHECK.
-- Those are *constraints*, taught in Week 3, and are added with ALTER TABLE.
-- (A table with no keys is legal SQL — but it is a bad design, which is the point of Week 3.)
--
-- Three columns are created "wrong" on purpose so Week 2's ALTER/RENAME commands have real work to do
-- (see 02_alter_tables.sql):
--   users.date_of_birth      missing              -> ADD COLUMN
--   devices.fingerprint      VARCHAR(32), old name -> RENAME COLUMN + MODIFY
--   merchants.merchant_name  VARCHAR(100)         -> MODIFY (too narrow)
--   fraud_alerts             wrong table name, has a stray `notes` column -> DROP COLUMN + RENAME TABLE
--
-- To re-run this week from scratch:   scripts/build.sh 2

USE sentinel;

-- ---- Reference tables ------------------------------------------------------

CREATE TABLE merchant_categories (
    category_id   INT,
    category_name VARCHAR(100),
    description   TEXT
);

CREATE TABLE locations (
    location_id INT,
    city        VARCHAR(100),
    state       VARCHAR(100),
    country     VARCHAR(100),
    latitude    DECIMAL(9,6),
    longitude   DECIMAL(9,6)
);

CREATE TABLE devices (
    device_id   INT,
    device_type ENUM('mobile', 'desktop', 'tablet'),
    os          VARCHAR(50),
    browser     VARCHAR(50),
    fingerprint VARCHAR(32)
);

CREATE TABLE rule_config (
    rule_id         INT,
    rule_name       VARCHAR(50),
    enabled         BOOLEAN,
    threshold_value DECIMAL(12,4),
    parameters_json JSON,
    updated_at      TIMESTAMP
);

-- ---- Master tables ---------------------------------------------------------

CREATE TABLE users (
    user_id    INT,
    full_name  VARCHAR(150),
    email      VARCHAR(255),
    phone      VARCHAR(20),
    created_at TIMESTAMP
);

CREATE TABLE accounts (
    account_id   INT,
    user_id      INT,
    account_type ENUM('savings', 'current'),
    balance      DECIMAL(14,2),
    status       ENUM('active', 'frozen', 'closed'),
    created_at   TIMESTAMP
);

CREATE TABLE merchants (
    merchant_id   INT,
    merchant_name VARCHAR(100),
    category_id   INT,
    city          VARCHAR(100),
    latitude      DECIMAL(9,6),
    longitude     DECIMAL(9,6),
    risk_score    DECIMAL(5,2)
);

-- ---- Relationship table (account <-> device is many-to-many) ---------------

CREATE TABLE account_devices (
    account_id INT,
    device_id  INT,
    first_seen TIMESTAMP,
    last_seen  TIMESTAMP
);

-- ---- Transactional tables --------------------------------------------------

CREATE TABLE transactions (
    txn_id        BIGINT,
    account_id    INT,
    merchant_id   INT,
    device_id     INT,
    location_id   INT,
    amount        DECIMAL(12,2),
    txn_time      TIMESTAMP,
    status        ENUM('success', 'pending', 'failed'),
    metadata_json JSON
);

CREATE TABLE fraud_alerts (
    alert_id    BIGINT,
    txn_id      BIGINT,
    rule_name   VARCHAR(50),
    risk_score  DECIMAL(5,2),
    reasons     JSON,
    status      ENUM('open', 'investigated', 'confirmed', 'false_positive'),
    created_at  TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    notes       VARCHAR(255)
);

-- ---- Historical / log tables ----------------------------------------------

CREATE TABLE behaviour_baselines (
    baseline_id         INT,
    account_id          INT,
    avg_amount          DECIMAL(12,2),
    stddev_amount       DECIMAL(12,2),
    peak_hours_json     JSON,
    typical_cities_json JSON,
    updated_at          TIMESTAMP
);

CREATE TABLE login_history (
    login_id    BIGINT,
    account_id  INT,
    device_id   INT,
    location_id INT,
    login_time  TIMESTAMP,
    success     BOOLEAN
);

CREATE TABLE audit_log (
    audit_id       BIGINT,
    table_name     VARCHAR(100),
    record_id      BIGINT,
    action         ENUM('INSERT', 'UPDATE', 'DELETE'),
    old_value_json JSON,
    new_value_json JSON,
    changed_by     VARCHAR(100),
    changed_at     TIMESTAMP
);
