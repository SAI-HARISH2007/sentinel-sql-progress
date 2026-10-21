-- Week 2 demo — every DDL command from the lab manual, on a THROWAWAY copy so the real tables stay untouched.
-- Run in order; it cleans up after itself.   mysql -uroot -p sentinel < demo/ddl_tour.sql
USE sentinel;

DROP TABLE IF EXISTS users_copy;
DROP TABLE IF EXISTS users_backup;

-- CREATE TABLE ... LIKE   (same structure, no rows)
CREATE TABLE users_copy LIKE users;
DESCRIBE users_copy;

-- ALTER ... ADD
ALTER TABLE users_copy ADD COLUMN city VARCHAR(30);
-- ALTER ... MODIFY (change datatype / width)
ALTER TABLE users_copy MODIFY city VARCHAR(60);
-- ALTER ... RENAME COLUMN
ALTER TABLE users_copy RENAME COLUMN city TO home_city;
-- ALTER ... DROP COLUMN
ALTER TABLE users_copy DROP COLUMN home_city;
DESCRIBE users_copy;
SHOW CREATE TABLE users_copy;

-- RENAME TABLE
RENAME TABLE users_copy TO users_backup;
SHOW TABLES LIKE 'users%';

-- TRUNCATE  (removes all rows, keeps the structure, resets AUTO_INCREMENT; cannot be rolled back)
TRUNCATE TABLE users_backup;

-- DROP TABLE  (removes rows AND the structure)
DROP TABLE users_backup;
SHOW TABLES LIKE 'users%';
