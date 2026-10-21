-- Week 4 assertions. Every row must say PASS.   (Counts are those of the committed seed file sql/20_seed_data.sql.)
USE sentinel;
SELECT 'users = 500',               IF((SELECT COUNT(*) FROM users)               = 500,   'PASS', 'FAIL');
SELECT 'accounts = 597',            IF((SELECT COUNT(*) FROM accounts)            = 597,   'PASS', 'FAIL');
SELECT 'merchants = 50',            IF((SELECT COUNT(*) FROM merchants)           = 50,    'PASS', 'FAIL');
SELECT 'merchant_categories = 10',  IF((SELECT COUNT(*) FROM merchant_categories) = 10,    'PASS', 'FAIL');
SELECT 'locations = 30',            IF((SELECT COUNT(*) FROM locations)           = 30,    'PASS', 'FAIL');
SELECT 'devices = 201',             IF((SELECT COUNT(*) FROM devices)             = 201,   'PASS', 'FAIL');
SELECT 'account_devices = 1780',    IF((SELECT COUNT(*) FROM account_devices)     = 1780,  'PASS', 'FAIL');
SELECT 'transactions = 12067',      IF((SELECT COUNT(*) FROM transactions)        = 12067, 'PASS', 'FAIL');
SELECT 'login_history = 200',       IF((SELECT COUNT(*) FROM login_history)       = 200,   'PASS', 'FAIL');
SELECT 'rule_config = 8 rows',      IF((SELECT COUNT(*) FROM rule_config)         = 8,     'PASS', 'FAIL');
SELECT 'zscore threshold is 3.0 (demo put it back)',
       IF((SELECT threshold_value FROM rule_config WHERE rule_name='zscore') = 3.0, 'PASS', 'FAIL');
SELECT 'no demo rows left behind',  IF((SELECT COUNT(*) FROM users WHERE user_id >= 90000) = 0, 'PASS', 'FAIL');
SELECT 'persona: the 95,000 txn from never-seen device 999 exists',
       IF((SELECT COUNT(*) FROM transactions WHERE txn_id = 12052 AND amount = 95000.00 AND device_id = 999) = 1, 'PASS', 'FAIL');
