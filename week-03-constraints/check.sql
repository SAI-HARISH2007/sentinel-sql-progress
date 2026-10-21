-- Week 3 assertions. Every row must say PASS.
USE sentinel;
SELECT 'every table has a PRIMARY KEY (13)',
       IF((SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_schema='sentinel' AND constraint_type='PRIMARY KEY') = 13, 'PASS', 'FAIL');
SELECT '13 FOREIGN KEYs',
       IF((SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_schema='sentinel' AND constraint_type='FOREIGN KEY') = 13, 'PASS', 'FAIL');
SELECT '7 UNIQUE constraints',
       IF((SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_schema='sentinel' AND constraint_type='UNIQUE') = 7, 'PASS', 'FAIL');
SELECT '4 CHECK constraints',
       IF((SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_schema='sentinel' AND constraint_type='CHECK') = 4, 'PASS', 'FAIL');
SELECT 'transactions.txn_id is AUTO_INCREMENT BIGINT',
       IF((SELECT CONCAT(column_type, '/', extra) FROM information_schema.columns WHERE table_schema='sentinel' AND table_name='transactions' AND column_name='txn_id') = 'bigint/auto_increment', 'PASS', 'FAIL');
SELECT 'accounts.status defaults to active',
       IF((SELECT column_default FROM information_schema.columns WHERE table_schema='sentinel' AND table_name='accounts' AND column_name='status') = 'active', 'PASS', 'FAIL');
SELECT 'ON DELETE CASCADE on accounts.user_id',
       IF((SELECT delete_rule FROM information_schema.referential_constraints WHERE constraint_schema='sentinel' AND constraint_name='fk_accounts_user') = 'CASCADE', 'PASS', 'FAIL');
SELECT 'ON DELETE RESTRICT on transactions.merchant_id',
       IF((SELECT delete_rule FROM information_schema.referential_constraints WHERE constraint_schema='sentinel' AND constraint_name='fk_txn_merchant') = 'RESTRICT', 'PASS', 'FAIL');
