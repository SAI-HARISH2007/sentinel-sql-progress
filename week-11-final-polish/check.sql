-- Week 11 assertions: the finished project as a whole. Every row must say PASS.
USE sentinel;
SELECT '13 tables',   IF((SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='sentinel' AND table_type='BASE TABLE') = 13, 'PASS', 'FAIL');
SELECT '11 views',    IF((SELECT COUNT(*) FROM information_schema.views  WHERE table_schema='sentinel') = 11, 'PASS', 'FAIL');
SELECT '5 stored routines (1 function, 4 procedures)', IF((SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='sentinel') = 5, 'PASS', 'FAIL');
SELECT '3 triggers',  IF((SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema='sentinel') = 3, 'PASS', 'FAIL');
SELECT '1 event',     IF((SELECT COUNT(*) FROM information_schema.events   WHERE event_schema='sentinel') = 1, 'PASS', 'FAIL');
SELECT '8 rule_config rows', IF((SELECT COUNT(*) FROM rule_config) = 8, 'PASS', 'FAIL');
SELECT '3 roles + 3 users', IF((SELECT COUNT(*) FROM mysql.user WHERE User IN ('fraud_analyst','txn_app','db_admin','analyst_user','app_user','admin_user')) = 6, 'PASS', 'FAIL');
SELECT 'every FK has an index on its column set', IF((SELECT COUNT(*) FROM information_schema.key_column_usage k
        WHERE k.table_schema='sentinel' AND k.referenced_table_name IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM information_schema.statistics s WHERE s.table_schema=k.table_schema AND s.table_name=k.table_name
                           AND s.column_name=k.column_name AND s.seq_in_index=1)) = 0, 'PASS', 'FAIL');
