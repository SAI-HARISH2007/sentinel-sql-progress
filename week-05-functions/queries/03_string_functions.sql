-- Week 5 — STRING (character) functions
USE sentinel;

-- Masking personal data for reports: analysts should not see full emails / phone numbers.
SELECT user_id,
       full_name,
       UPPER(full_name)                                  AS name_upper,
       LENGTH(full_name)                                 AS name_length,
       CONCAT(LEFT(email, 2), REPEAT('*', INSTR(email, '@') - 3), SUBSTRING(email, INSTR(email, '@'))) AS masked_email,
       CONCAT('******', RIGHT(phone, 4))                 AS masked_phone,
       SUBSTRING_INDEX(email, '@', -1)                   AS email_domain
FROM users
WHERE user_id <= 5;

-- LOWER, TRIM, REPLACE, LPAD, CONCAT_WS, LOCATE, REVERSE
SELECT LOWER('  FRAUD Alert  ')                     AS lower_text,
       CONCAT('[', TRIM('  FRAUD Alert  '), ']')    AS trimmed,
       REPLACE('Impossible travel', ' ', '_')       AS snake_case,
       LPAD(12052, 8, '0')                          AS padded_txn_id,
       CONCAT_WS(' | ', 'New device', 'High amount', 'Off-hours') AS reasons_joined,
       LOCATE('travel', 'Impossible travel')        AS position_of_travel,
       REVERSE('abc')                               AS reversed;

-- Building the human-readable "reason" text that alerts will carry (Weeks 9-10)
SELECT txn_id,
       amount,
       CONCAT('High amount (₹', FORMAT(amount, 2), ')') AS reason_text
FROM transactions
WHERE amount > 90000;

-- Device fingerprints are 64-character hashes; reports show only the start
SELECT device_id, LEFT(fingerprint_hash, 8) AS fingerprint_prefix, CONCAT(os, ' / ', browser) AS platform
FROM devices
WHERE device_id IN (1, 2, 999);
