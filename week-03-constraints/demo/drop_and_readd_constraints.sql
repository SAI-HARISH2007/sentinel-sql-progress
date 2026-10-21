-- Week 3 demo — the "DROP" half of the lab manual's constraints list.
-- Each constraint is dropped and immediately put back exactly as it was, so the schema is unchanged afterwards.
USE sentinel;

-- DROP a CHECK constraint
ALTER TABLE transactions DROP CHECK chk_txn_amount;
ALTER TABLE transactions ADD CONSTRAINT chk_txn_amount CHECK (amount > 0);

-- DROP a FOREIGN KEY   (note: the *index* behind it stays; drop it separately with DROP INDEX if you want it gone)
ALTER TABLE accounts DROP FOREIGN KEY fk_accounts_user;
ALTER TABLE accounts ADD CONSTRAINT fk_accounts_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- DROP a UNIQUE constraint   (in MySQL a UNIQUE constraint IS a unique index, so it is dropped with DROP INDEX)
ALTER TABLE users DROP INDEX email;
ALTER TABLE users ADD UNIQUE (email);

-- DROP a DEFAULT
ALTER TABLE accounts ALTER COLUMN status DROP DEFAULT;
ALTER TABLE accounts ALTER COLUMN status SET DEFAULT 'active';

-- DROP PRIMARY KEY would first require dropping every foreign key that points at it, so it is not demonstrated here.
-- Try it on the scratch table from Week 2:   CREATE TABLE t LIKE users;  ALTER TABLE t DROP PRIMARY KEY;

-- What the constraints on one table look like now:
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'sentinel' AND table_name = 'transactions'
ORDER BY constraint_type, constraint_name;
