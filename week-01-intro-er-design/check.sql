-- Week 1 assertions. Every row must say PASS.
SELECT 'database sentinel exists',
       IF((SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='sentinel') = 1, 'PASS', 'FAIL');
SELECT 'charset is utf8mb4',
       IF((SELECT default_character_set_name FROM information_schema.schemata WHERE schema_name='sentinel') = 'utf8mb4', 'PASS', 'FAIL');
