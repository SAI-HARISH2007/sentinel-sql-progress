-- =============================================================================
-- Week 2 — DDL: ALTER, RENAME, DROP COLUMN
-- 02_alter_tables.sql — fix the four deliberate flaws left by 01_create_tables.sql
-- =============================================================================
-- Every command in the lab manual's DDL list appears here doing real work.
-- NOTE the MySQL syntax: NO parentheses around the column in MODIFY / DROP COLUMN / RENAME COLUMN.
-- (The manual's examples use Oracle-style parentheses; MySQL rejects them.)

USE sentinel;

-- ALTER TABLE ... ADD COLUMN   (we forgot the date of birth)
ALTER TABLE users ADD COLUMN date_of_birth DATE AFTER phone;

-- ALTER TABLE ... RENAME COLUMN   (the column should say what it holds: a hash)
ALTER TABLE devices RENAME COLUMN fingerprint TO fingerprint_hash;

-- ALTER TABLE ... MODIFY   (a SHA-256 hash is 64 hex characters; 32 would truncate or fail)
ALTER TABLE devices MODIFY fingerprint_hash VARCHAR(64);

-- ALTER TABLE ... MODIFY   (company names longer than 100 characters exist)
ALTER TABLE merchants MODIFY merchant_name VARCHAR(200);

-- ALTER TABLE ... DROP COLUMN   (free-text notes do not belong in the alerts table; the audit_log handles history)
ALTER TABLE fraud_alerts DROP COLUMN notes;

-- RENAME TABLE   (the table is called `alerts` everywhere in the design documents)
RENAME TABLE fraud_alerts TO alerts;
