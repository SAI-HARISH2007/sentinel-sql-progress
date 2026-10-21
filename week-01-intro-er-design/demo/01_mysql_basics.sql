-- Week 1 demo — the five commands the lab manual's "Introduction to MySQL" page teaches.
-- Run:  mysql -uroot -p < demo/01_mysql_basics.sql     (or paste into Workbench)

SELECT VERSION() AS mysql_version;
SHOW DATABASES;            -- sentinel must be in this list
USE sentinel;
SELECT DATABASE() AS current_database;
SHOW TABLES;               -- empty this week: tables arrive in Week 2 (DDL)

-- The database's character set and collation (we chose utf8mb4 so names/emails in any language fit):
SELECT default_character_set_name, default_collation_name
FROM information_schema.schemata WHERE schema_name = 'sentinel';
