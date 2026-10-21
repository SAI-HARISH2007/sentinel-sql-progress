-- =============================================================================
-- Week 3 — Constraints: PRIMARY KEY, NOT NULL, UNIQUE, DEFAULT, CHECK, FOREIGN KEY
-- 01_constraints.sql — turn the bare Week 2 tables into a protected schema
-- =============================================================================
-- Order matters:  keys first (FOREIGN KEYs need a PRIMARY KEY or UNIQUE key to point at),
-- foreign keys LAST (the parent tables must already have their keys).
-- "NULL" from the lab manual's list is the default state of a column: any column that never
-- gets NOT NULL below (phone, description, state, metadata_json, reviewed_at ...) is deliberately optional.
--
-- Every statement is an ALTER TABLE on a table created in Week 2.

USE sentinel;

-- =============================================================================
-- 1. PRIMARY KEY  (+ AUTO_INCREMENT so the database hands out the ids)
-- =============================================================================
ALTER TABLE merchant_categories MODIFY category_id INT    AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE locations           MODIFY location_id INT    AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE devices             MODIFY device_id   INT    AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE rule_config         MODIFY rule_id     INT    AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE users               MODIFY user_id     INT    AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE accounts            MODIFY account_id  INT    AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE merchants           MODIFY merchant_id INT    AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE transactions        MODIFY txn_id      BIGINT AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE alerts              MODIFY alert_id    BIGINT AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE behaviour_baselines MODIFY baseline_id INT    AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE login_history       MODIFY login_id    BIGINT AUTO_INCREMENT PRIMARY KEY;
ALTER TABLE audit_log           MODIFY audit_id    BIGINT AUTO_INCREMENT PRIMARY KEY;

-- Composite primary key: one row per (account, device) pair. This is what makes the M:N table work.
ALTER TABLE account_devices ADD PRIMARY KEY (account_id, device_id);

-- =============================================================================
-- 2. NOT NULL
-- =============================================================================
ALTER TABLE merchant_categories MODIFY category_name VARCHAR(100) NOT NULL;

ALTER TABLE locations
    MODIFY city      VARCHAR(100)  NOT NULL,
    MODIFY country   VARCHAR(100)  NOT NULL,
    MODIFY latitude  DECIMAL(9,6)  NOT NULL,
    MODIFY longitude DECIMAL(9,6)  NOT NULL;

ALTER TABLE devices
    MODIFY device_type      ENUM('mobile', 'desktop', 'tablet') NOT NULL,
    MODIFY fingerprint_hash VARCHAR(64) NOT NULL;

ALTER TABLE rule_config
    MODIFY rule_name       VARCHAR(50)   NOT NULL,
    MODIFY enabled         BOOLEAN       NOT NULL,
    MODIFY threshold_value DECIMAL(12,4) NOT NULL;

ALTER TABLE users
    MODIFY full_name VARCHAR(150) NOT NULL,
    MODIFY email     VARCHAR(255) NOT NULL;

ALTER TABLE accounts
    MODIFY user_id      INT NOT NULL,
    MODIFY account_type ENUM('savings', 'current') NOT NULL,
    MODIFY balance      DECIMAL(14,2) NOT NULL,
    MODIFY status       ENUM('active', 'frozen', 'closed') NOT NULL;

ALTER TABLE merchants
    MODIFY merchant_name VARCHAR(200)  NOT NULL,
    MODIFY category_id   INT           NOT NULL,
    MODIFY city          VARCHAR(100)  NOT NULL,
    MODIFY latitude      DECIMAL(9,6)  NOT NULL,
    MODIFY longitude     DECIMAL(9,6)  NOT NULL;

ALTER TABLE transactions
    MODIFY account_id  INT NOT NULL,
    MODIFY merchant_id INT NOT NULL,
    MODIFY device_id   INT NOT NULL,
    MODIFY location_id INT NOT NULL,
    MODIFY amount      DECIMAL(12,2) NOT NULL,
    MODIFY txn_time    TIMESTAMP NOT NULL,
    MODIFY status      ENUM('success', 'pending', 'failed') NOT NULL;

ALTER TABLE alerts
    MODIFY txn_id     BIGINT       NOT NULL,
    MODIFY rule_name  VARCHAR(50)  NOT NULL,
    MODIFY risk_score DECIMAL(5,2) NOT NULL,
    MODIFY status     ENUM('open', 'investigated', 'confirmed', 'false_positive') NOT NULL;

ALTER TABLE behaviour_baselines MODIFY account_id INT NOT NULL;

ALTER TABLE login_history
    MODIFY account_id  INT NOT NULL,
    MODIFY device_id   INT NOT NULL,
    MODIFY location_id INT NOT NULL,
    MODIFY success     BOOLEAN NOT NULL;

ALTER TABLE audit_log
    MODIFY table_name VARCHAR(100) NOT NULL,
    MODIFY record_id  BIGINT       NOT NULL,
    MODIFY action     ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL;

-- =============================================================================
-- 3. UNIQUE   (candidate keys that are not the primary key)
-- =============================================================================
ALTER TABLE merchant_categories ADD UNIQUE (category_name);
ALTER TABLE locations           ADD CONSTRAINT uq_city_country UNIQUE (city, country);
ALTER TABLE devices             ADD UNIQUE (fingerprint_hash);
ALTER TABLE rule_config         ADD UNIQUE (rule_name);
ALTER TABLE users               ADD UNIQUE (email);
ALTER TABLE alerts              ADD UNIQUE (txn_id);          -- one alert per transaction (1:1)
ALTER TABLE behaviour_baselines ADD UNIQUE (account_id);      -- one baseline per account (1:1)

-- =============================================================================
-- 4. DEFAULT
-- =============================================================================
-- Two syntaxes. ALTER COLUMN ... SET DEFAULT changes only the default and leaves the rest of the column alone.
ALTER TABLE locations   ALTER COLUMN country      SET DEFAULT 'India';
ALTER TABLE rule_config ALTER COLUMN enabled      SET DEFAULT TRUE;
ALTER TABLE accounts
    ALTER COLUMN account_type SET DEFAULT 'savings',
    ALTER COLUMN balance      SET DEFAULT 0.00,
    ALTER COLUMN status       SET DEFAULT 'active';
ALTER TABLE merchants     ALTER COLUMN risk_score SET DEFAULT 0.00;
ALTER TABLE transactions  ALTER COLUMN status     SET DEFAULT 'success';
ALTER TABLE alerts        ALTER COLUMN status     SET DEFAULT 'open';
ALTER TABLE login_history ALTER COLUMN success    SET DEFAULT TRUE;

-- Timestamps: MODIFY restates the column so we can also add  ON UPDATE CURRENT_TIMESTAMP  (auto "last changed" stamp).
ALTER TABLE rule_config         MODIFY updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE users               MODIFY created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE accounts            MODIFY created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE account_devices
    MODIFY first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    MODIFY last_seen  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE transactions        MODIFY txn_time   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE alerts              MODIFY created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE behaviour_baselines MODIFY updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE login_history       MODIFY login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE audit_log           MODIFY changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- =============================================================================
-- 5. CHECK   (enforced from MySQL 8.0.16 onward; older versions parse and silently ignore it)
-- =============================================================================
ALTER TABLE transactions ADD CONSTRAINT chk_txn_amount     CHECK (amount > 0);
ALTER TABLE accounts     ADD CONSTRAINT chk_accounts_balance CHECK (balance >= 0);
ALTER TABLE locations    ADD CONSTRAINT chk_loc_latitude   CHECK (latitude  BETWEEN  -90 AND  90);
ALTER TABLE locations    ADD CONSTRAINT chk_loc_longitude  CHECK (longitude BETWEEN -180 AND 180);

-- =============================================================================
-- 6. FOREIGN KEY   (referential integrity; the ON DELETE rule is a design decision, see README)
-- =============================================================================
-- CASCADE  : delete the parent -> its children are deleted too (data that is meaningless without the parent)
-- RESTRICT : refuse to delete a parent that still has children (data we must never silently lose)
ALTER TABLE accounts
    ADD CONSTRAINT fk_accounts_user     FOREIGN KEY (user_id)     REFERENCES users(user_id)                      ON DELETE CASCADE;
ALTER TABLE merchants
    ADD CONSTRAINT fk_merchants_category FOREIGN KEY (category_id) REFERENCES merchant_categories(category_id)   ON DELETE RESTRICT;
ALTER TABLE account_devices
    ADD CONSTRAINT fk_ad_account        FOREIGN KEY (account_id)  REFERENCES accounts(account_id)               ON DELETE CASCADE,
    ADD CONSTRAINT fk_ad_device         FOREIGN KEY (device_id)   REFERENCES devices(device_id)                 ON DELETE CASCADE;
ALTER TABLE transactions
    ADD CONSTRAINT fk_txn_account       FOREIGN KEY (account_id)  REFERENCES accounts(account_id)               ON DELETE CASCADE,
    ADD CONSTRAINT fk_txn_merchant      FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)             ON DELETE RESTRICT,
    ADD CONSTRAINT fk_txn_device        FOREIGN KEY (device_id)   REFERENCES devices(device_id)                 ON DELETE RESTRICT,
    ADD CONSTRAINT fk_txn_location      FOREIGN KEY (location_id) REFERENCES locations(location_id)             ON DELETE RESTRICT;
ALTER TABLE alerts
    ADD CONSTRAINT fk_alert_txn         FOREIGN KEY (txn_id)      REFERENCES transactions(txn_id)               ON DELETE CASCADE;
ALTER TABLE behaviour_baselines
    ADD CONSTRAINT fk_bb_account        FOREIGN KEY (account_id)  REFERENCES accounts(account_id)               ON DELETE CASCADE;
ALTER TABLE login_history
    ADD CONSTRAINT fk_lh_account        FOREIGN KEY (account_id)  REFERENCES accounts(account_id)               ON DELETE CASCADE,
    ADD CONSTRAINT fk_lh_device         FOREIGN KEY (device_id)   REFERENCES devices(device_id)                 ON DELETE RESTRICT,
    ADD CONSTRAINT fk_lh_location       FOREIGN KEY (location_id) REFERENCES locations(location_id)             ON DELETE RESTRICT;
