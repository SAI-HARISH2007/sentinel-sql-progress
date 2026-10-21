-- Week 2 assertions. Every row must say PASS.
USE sentinel;
SELECT '13 tables exist (no leftovers)',
       IF((SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='sentinel' AND table_type='BASE TABLE') = 13, 'PASS', 'FAIL');
SELECT 'alerts exists, fraud_alerts is gone',
       IF((SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='sentinel' AND table_name='alerts') = 1
      AND (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='sentinel' AND table_name='fraud_alerts') = 0, 'PASS', 'FAIL');
SELECT 'alerts.notes was dropped',
       IF((SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='sentinel' AND table_name='alerts' AND column_name='notes') = 0, 'PASS', 'FAIL');
SELECT 'users.date_of_birth was added after phone',
       IF((SELECT ordinal_position FROM information_schema.columns WHERE table_schema='sentinel' AND table_name='users' AND column_name='date_of_birth')
        = (SELECT ordinal_position + 1 FROM information_schema.columns WHERE table_schema='sentinel' AND table_name='users' AND column_name='phone'), 'PASS', 'FAIL');
SELECT 'devices.fingerprint_hash is VARCHAR(64)',
       IF((SELECT column_type FROM information_schema.columns WHERE table_schema='sentinel' AND table_name='devices' AND column_name='fingerprint_hash') = 'varchar(64)', 'PASS', 'FAIL');
SELECT 'merchants.merchant_name is VARCHAR(200)',
       IF((SELECT column_type FROM information_schema.columns WHERE table_schema='sentinel' AND table_name='merchants' AND column_name='merchant_name') = 'varchar(200)', 'PASS', 'FAIL');
