# Sentinel — In-Database Real-Time Fraud Detection System
### Database Management Systems (CS/AI/AIM/DS 202) — Mini Project Report


**Institution:** ICFAI Foundation for Higher Education, Faculty of Science & Technology, Hyderabad

**Programme:** B.Tech CSE (AI & ML), Semester III, A.Y. 2026-27

**Team:** Sai Haresh Anand S · Seshivardhini

**Repository:** https://github.com/SAI-HARISH2007/sentinel-sql-progress
**Database:** MySQL 8.4 (Docker)

## Abstract
Fraud checks usually live in application code: hard-coded thresholds, a gap between commit and check, and a separate copy of the data.
Sentinel moves the check *into the database*. A trigger on `INSERT INTO transactions` calls a stored procedure that scores the new row against
six rules (high amount, off-hours, new device, velocity, impossible travel, merchant risk), each measured against that account's own history,
and writes an alert with human-readable reasons. Thresholds live in a table, so tuning is an `UPDATE`.

The report is organised **week by week**, following the course's lab sequence. Each page was added in the week the matching lab was done,
and every query result shown was captured by running the repository's own scripts on the finished database.

| Week | Lab topic | Adds to the project |
|---|---|---|
| 1 | Introduction to MySQL & database design (ER) | Design before you build. |
| 2 | DDL: CREATE, ALTER, DROP, TRUNCATE, RENAME | Create all 13 tables with columns and data types only. |
| 3 | Constraints: PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, DEFAULT, CHECK | Turn the bare tables into a self-defending schema. |
| 4 | DML: INSERT, UPDATE, DELETE, SELECT | Put data in. |
| 5 | Functions: number, aggregate, string, date | Use every function family on real data, and use them to build the first three pieces of fraud logic by hand: the z-score (Rule 1), the hour of day (Rule 2) and the distance and speed between cities (Rule 5). |
| 6 | Operators: arithmetic, comparison, logical, special, set | Every operator family on real data, ending in a deliberately naive "first-cut fraud screen" built from fixed thresholds, which shows *why* the later weeks compare each account with its own history. |
| 7 | Joins: inner, outer, natural, self | Combine tables. |
| 8 | GROUP BY, HAVING, ORDER BY — and subqueries | Aggregate per group and filter groups. |
| 9 | Views and indexes (plus DCL: roles, GRANT, REVOKE) | Package the eight weeks of queries as named, reusable views, speed up the access paths with measured indexes, and lock the data down with roles. |
| 10 | Stored procedures, triggers — and transactions | The finale: the same six rules, now as one stored procedure that a trigger runs on every INSERT. |
| 11 | Testing, documentation and the demo | Prove it works, write it up, rehearse it. |

---

# Week 1 — Introduction to MySQL & database design (ER)

[Project README](../../README.md) · [Week 2 →](../../week-02-ddl/README.md)

**Lab:** Handout lab list **#1 — Introduction to MySQL and ER Diagram**  ·  lab manual **Experiment 0/1 — Introduction to SQL & MySQL and Database Design**
**Theory lectures this lines up with:** 1–9 (introduction to databases, ER modelling, ER → relational design)

Design before you build. You create the empty `sentinel` database and, more importantly, write down the problem, the requirements, the ER diagram and the rules that turn that diagram into tables. No table exists yet.

## What was added

| File | What it is |
|---|---|
| `sql/01_create_database.sql` | `DROP/CREATE DATABASE sentinel`, utf8mb4. Every later week starts from this. |
| `docs/problem-statement.md` | Handout steps 1-4: title, problem, objectives, functional + non-functional requirements, the six fraud signals. |
| `docs/er-diagram.md · er-diagram.dbml` | The ER diagram (Mermaid, renders on GitHub) and DBML for dbdiagram.io. **Generated from the real schema**, never hand-edited. |
| `docs/er-to-relational.md` | Which ER-to-tables rule produced which table (strong entity, 1:N, M:N, 1:1, participation, derived attribute). |
| `demo/01_mysql_basics.sql` | `SHOW DATABASES`, `USE`, `SHOW TABLES`, `VERSION()`: the commands in the lab manual's intro page. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- `SHOW DATABASES` lists `sentinel`; `SHOW TABLES` is empty (tables arrive in Week 2).
- Character set `utf8mb4`, collation `utf8mb4_unicode_ci`.

## Concepts you must be able to explain (viva)

- **DBMS vs file system.** A DBMS adds integrity rules, concurrent access control, security and data independence that plain files lack.
- **The five parts of SQL.** DDL (structure) · DML (change data) · DRL (SELECT) · TCL (COMMIT/ROLLBACK) · DCL (GRANT/REVOKE). The lab manual lists exactly these five.
- **ER vocabulary.** Entity, entity set, attribute (simple/composite/multivalued/derived), relationship, cardinality (1:1, 1:N, M:N), participation (total/partial), weak entity.
- **ER → relational.** Read `docs/er-to-relational.md` twice. Each row is a Part B/C exam answer.
- **Why surrogate keys.** `email`, `fingerprint_hash` are candidate keys; a small `INT` id is the primary key because it is compact in every foreign key and index.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout steps 1-5 (title, problem, objectives, requirements, ER model).

## Results (captured from the running database)

### Evidence: Database and character set

Script: [`week-01-intro-er-design/demo/01_mysql_basics.sql`](../../week-01-intro-er-design/demo/01_mysql_basics.sql)

```text
+---------------+
| mysql_version |
+---------------+
| 8.4.11        |
+---------------+
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sentinel           |
| sys                |
+--------------------+
+------------------+
| current_database |
+------------------+
| sentinel         |
+------------------+
+------------------------+
| Tables_in_sentinel     |
+------------------------+
| account_devices        |
| accounts               |
| alerts                 |
| audit_log              |
| behaviour_baselines    |
| devices                |
| locations              |
| login_history          |
... (22 more lines)
```


---

# Week 2 — DDL: CREATE, ALTER, DROP, TRUNCATE, RENAME



**Lab:** Handout lab list **#2 — Data Definition Language** (CREATE, ALTER, DROP, TRUNCATE, RENAME)  ·  lab manual **"Experiment 2: DDL COMMANDS"** (its index calls it Experiment 1)
**Theory lectures this lines up with:** 12–17 (basic SQL: DDL)

Create all 13 tables with columns and data types only. Four things are created deliberately wrong so the ALTER / RENAME commands have real work to do. No keys, no defaults: that is next week.

## What was added

| File | What it is |
|---|---|
| `sql/01_create_tables.sql` | 13 `CREATE TABLE` statements: columns and types, nothing else. |
| `sql/02_alter_tables.sql` | `ADD COLUMN`, `RENAME COLUMN`, `MODIFY`, `DROP COLUMN`, `RENAME TABLE`, each fixing one deliberate flaw. |
| `demo/ddl_tour.sql` | Every DDL command from the manual on a throw-away copy (`CREATE TABLE … LIKE`), cleaned up afterwards. |
| `lab-practice/ddl_employee.sql` | **The lab manual's 9-question DDL assignment (EMPLOYEE table), solved in MySQL**, in its own `lab_practice` database. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- 13 tables (`SHOW TABLES`). `DESCRIBE users` has `date_of_birth` right after `phone`, and the `Key` column is **empty** for every table.
- `devices.fingerprint_hash` is `varchar(64)`; `merchants.merchant_name` is `varchar(200)`; `fraud_alerts` is now called `alerts` and has no `notes` column.

## Concepts you must be able to explain (viva)

- **Data types.** `INT`, `BIGINT`, `DECIMAL(p,s)` (exact: use for money, never FLOAT), `CHAR` vs `VARCHAR`, `TEXT`, `ENUM`, `JSON`, `TIMESTAMP`, `BOOLEAN` (= `TINYINT(1)`).
- **ALTER TABLE.** `ADD`, `MODIFY` (change type/width), `RENAME COLUMN`, `DROP COLUMN`.
- **DELETE vs TRUNCATE vs DROP.** DELETE: chosen rows, can roll back, fires triggers. TRUNCATE: all rows, DDL, resets AUTO_INCREMENT, no rollback. DROP: rows *and* table.
- **DDL commits implicitly.** You cannot ROLLBACK a CREATE/ALTER/DROP/TRUNCATE.
- **Why bare tables first?.** A table without keys is legal but unsafe: it would accept duplicate users and orphan transactions. Week 3 shows the fix.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout step 7 (SQL implementation: DDL).

## Results (captured from the running database)

### Evidence: Every DDL command on a throw-away table

Script: [`week-02-ddl/demo/ddl_tour.sql`](../../week-02-ddl/demo/ddl_tour.sql)

```text
+---------------+--------------+------+-----+-------------------+-------------------+
| Field         | Type         | Null | Key | Default           | Extra             |
+---------------+--------------+------+-----+-------------------+-------------------+
| user_id       | int          | NO   | PRI | NULL              | auto_increment    |
| full_name     | varchar(150) | NO   |     | NULL              |                   |
| email         | varchar(255) | NO   | UNI | NULL              |                   |
| phone         | varchar(20)  | YES  |     | NULL              |                   |
| date_of_birth | date         | YES  |     | NULL              |                   |
| created_at    | timestamp    | YES  |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
+---------------+--------------+------+-----+-------------------+-------------------+
+---------------+--------------+------+-----+-------------------+-------------------+
| Field         | Type         | Null | Key | Default           | Extra             |
+---------------+--------------+------+-----+-------------------+-------------------+
| user_id       | int          | NO   | PRI | NULL              | auto_increment    |
| full_name     | varchar(150) | NO   |     | NULL              |                   |
| email         | varchar(255) | NO   | UNI | NULL              |                   |
| phone         | varchar(20)  | YES  |     | NULL              |                   |
| date_of_birth | date         | YES  |     | NULL              |                   |
| created_at    | timestamp    | YES  |     | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
+---------------+--------------+------+-----+-------------------+-------------------+
+------------+------------------------------------------------------------------------------------------------------------------------------------------------------------
| Table      | Create Table                                                                                                                                               
+------------+------------------------------------------------------------------------------------------------------------------------------------------------------------
| users_copy | CREATE TABLE `users_copy` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci |
+------------+------------------------------------------------------------------------------------------------------------------------------------------------------------
+-----------------------------+
| Tables_in_sentinel (users%) |
+-----------------------------+
| users                       |
| users_backup                |
+-----------------------------+
+-----------------------------+
| Tables_in_sentinel (users%) |
+-----------------------------+
| users                       |
+-----------------------------+
```


---

# Week 3 — Constraints: PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, DEFAULT, CHECK



**Lab:** Handout lab list **#3 — Constraints** (PRIMARY KEY, FOREIGN KEY, UNIQUE, NULL, NOT NULL, DEFAULT, CHECK, DROP)  ·  lab manual "Constraints"
**Theory lectures this lines up with:** 12–17 (keys, constraints); 23–25 (normalization) for `docs/normalization.md`

Turn the bare tables into a self-defending schema. Every rule is added with `ALTER TABLE` in the order the manual lists them, so you can see each constraint appear.

## What was added

| File | What it is |
|---|---|
| `sql/01_constraints.sql` | Primary keys (+ AUTO_INCREMENT), NOT NULL, UNIQUE, DEFAULT, CHECK, FOREIGN KEY with ON DELETE rules. |
| `demo/constraint_violations.sql` | Makes every constraint fire: six statements that **must fail**, with the exact MySQL error code, plus one CASCADE that succeeds. |
| `demo/drop_and_readd_constraints.sql` | The manual's *DROP* part: drop and restore a CHECK, a FOREIGN KEY, a UNIQUE and a DEFAULT. |
| `docs/normalization.md` | The 1NF / 2NF / 3NF / BCNF argument, table by table. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- 13 PRIMARY KEY, 13 FOREIGN KEY, 7 UNIQUE, 4 CHECK constraints.
- The violation demo prints, in order: **1062** (dup primary key), **1062** (dup unique), **1048** (NULL), **1452** (missing parent), **3819** (CHECK), **1451** (RESTRICT). The CASCADE then shows `accounts_left_after_cascade = 0`.

## Concepts you must be able to explain (viva)

- **Primary key vs unique.** One PK per table, never NULL. Any number of UNIQUE keys. Both are candidate keys.
- **Composite key.** `account_devices` is identified by the *pair* `(account_id, device_id)`.
- **Foreign key + ON DELETE.** CASCADE deletes children; RESTRICT blocks the delete. Choose per relationship: see the table in the SQL file.
- **CHECK.** Enforced from MySQL 8.0.16; older versions silently ignore it.
- **NULL.** "Unknown", not zero or empty. A column never given NOT NULL is deliberately optional.
- **Order matters.** Keys first, foreign keys last: an FK needs a PK/UNIQUE key to point at.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout steps 6-7 (schema design, normalisation; SQL implementation).

## Results (captured from the running database)

### Evidence: Constraints firing (errors are the expected result)

Script: [`week-03-constraints/demo/constraint_violations.sql`](../../week-03-constraints/demo/constraint_violations.sql)

```text
+------------+--------------+---------+--------+
| account_id | account_type | balance | status |
+------------+--------------+---------+--------+
|      99001 | savings      |    0.00 | active |
+------------+--------------+---------+--------+
+-----------------------------+
| accounts_left_after_cascade |
+-----------------------------+
|                           0 |
+-----------------------------+
ERROR 1062 (23000) at line 11: Duplicate entry '99001' for key 'merchant_categories.PRIMARY'
ERROR 1062 (23000) at line 14: Duplicate entry 'Demo category' for key 'merchant_categories.category_name'
ERROR 1048 (23000) at line 17: Column 'full_name' cannot be null
ERROR 1452 (23000) at line 20: Cannot add or update a child row: a foreign key constraint fails (`sentinel`.`accounts`, CONSTRAINT `fk_accounts_user` FOREIGN KEY (`user_i
ERROR 3819 (HY000) at line 23: Check constraint 'chk_txn_amount' is violated.
ERROR 1451 (23000) at line 29: Cannot delete or update a parent row: a foreign key constraint fails (`sentinel`.`merchants`, CONSTRAINT `fk_merchants_category` FOREIGN KE
```


---

# Week 4 — DML: INSERT, UPDATE, DELETE, SELECT



**Lab:** Handout lab list **#4 — Data Manipulation Language** (SELECT, INSERT, UPDATE, DELETE)  ·  lab manual "Experiment 3: DML COMMANDS"
**Theory lectures this lines up with:** 12–17 (basic SQL: DML)

Put data in. The detector's thresholds go into `rule_config`, and a deterministic generator loads 500 users, 12,067 transactions and five planted fraud personas. From now on every week queries the same data.

## What was added

| File | What it is |
|---|---|
| `sql/10_rule_config.sql` | 8 tuning rows (z-score limit, velocity limit, …). The detector will read these; changing them is an UPDATE. |
| `sql/20_seed_data.sql` | The generated data set. **Committed**, so nobody needs Python to build the project. |
| `seed/generate.py` | The generator (Faker, fixed random seed). Re-run only if you want different data. |
| `demo/dml_tour.sql` | Single-row, multi-row and `INSERT … SELECT`; UPDATE; DELETE; a CASCADE; self-cleaning. |
| `lab-practice/dml_employee.sql` | **The manual's 9-question DML assignment (EMPLOYEE table), solved.** |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- users 500 · accounts 597 · merchants 50 · merchant_categories 10 · locations 30 · devices 201 · account_devices 1,780 · login_history 200 · **transactions 12,067** · rule_config 8.
- Personas, all on rows 12041-12067: **traveller** 12041/12042 (Delhi then Chennai, 10 min apart) · **night_owl** 12043 (02:30) · **burst** 12044-12051 (8 payments in 3 min) · **new_device_big** 12052 (₹95,000 from device 999) · **bad_merchant** 12053-12067 (15 large payments at merchant 50).

## Concepts you must be able to explain (viva)

- **Three INSERT forms.** One row · many rows in one statement · `INSERT … SELECT`.
- **UPDATE / DELETE need WHERE.** Without it they change *every* row. This is the classic exam trap.
- **Defaults in action.** `INSERT INTO accounts (account_id, user_id)` gives savings / 0.00 / active, because of Week 3.
- **CASCADE in action.** Deleting user 90001 removes their account (demo).
- **Config as data.** Thresholds in a table mean tuning needs no code change and no redeploy.
- **Why `SET autocommit = 0` in the seed.** One commit for 15,000 inserts instead of 15,000 commits: far faster.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout step 7 (SQL implementation: DML) and step 11 (test data).

## Results (captured from the running database)

### Evidence: INSERT / UPDATE / DELETE tour

Script: [`week-04-dml/demo/dml_tour.sql`](../../week-04-dml/demo/dml_tour.sql)

```text
+---------+------------+-------------------+---------------+---------------+---------------------+
| user_id | full_name  | email             | phone         | date_of_birth | created_at          |
+---------+------------+-------------------+---------------+---------------+---------------------+
|   90001 | Demo One   | demo1@example.com | +919000000001 | 2005-05-05    | 2026-10-08 02:12:15 |
|   90002 | Demo Two   | demo2@example.com | NULL          | NULL          | 2026-10-08 02:12:15 |
|   90003 | Demo Three | demo3@example.com | NULL          | NULL          | 2026-10-08 02:12:15 |
+---------+------------+-------------------+---------------+---------------+---------------------+
+------------+--------------+---------+--------+---------------------+
| account_id | account_type | balance | status | created_at          |
+------------+--------------+---------+--------+---------------------+
|      90001 | savings      |    0.00 | active | 2026-10-08 02:12:15 |
+------------+--------------+---------+--------+---------------------+
+-------------+----------------------------+--------+
| merchant_id | merchant_name              | city   |
+-------------+----------------------------+--------+
|          16 | Miller, Davis and Anderson | Mumbai |
|          14 | Morse PLC                  | Mumbai |
+-------------+----------------------------+--------+
+---------+
| status  |
+---------+
| failed  |
| success |
| pending |
+---------+
+--------+------------+----------+---------------------+
| txn_id | account_id | amount   | txn_time            |
+--------+------------+----------+---------------------+
|  12052 |          1 | 95000.00 | 2026-08-18 11:00:00 |
|  12059 |        285 | 69888.23 | 2026-08-19 18:00:00 |
|  12053 |        117 | 66536.48 | 2026-08-19 12:00:00 |
|  12062 |        165 | 62629.96 | 2026-08-19 21:00:00 |
|  12061 |        158 | 61521.54 | 2026-08-19 20:00:00 |
+--------+------------+----------+---------------------+
+------------+---------+
| account_id | balance |
+------------+---------+
|      90001 | 5000.00 |
+------------+---------+
+-----------+-----------------+---------------------+
| rule_name | threshold_value | updated_at          |
+-----------+-----------------+---------------------+
| zscore    |          3.0000 | 2026-10-08 02:06:16 |
+-----------+-----------------+---------------------+
+-----------+-----------------+---------------------+
| rule_name | threshold_value | updated_at          |
+-----------+-----------------+---------------------+
| zscore    |          2.5000 | 2026-10-08 02:12:15 |
+-----------+-----------------+---------------------+
+-----------------+
| demo_users_left |
+-----------------+
|               2 |
+-----------------+
+--------------------+
| demo_accounts_left |
+--------------------+
|                  0 |
+--------------------+
```


---

# Week 5 — Functions: number, aggregate, string, date



**Lab:** Handout lab list **#5 — Functions** (NUMBER, AGGREGATE, CHARACTER, DATE)  ·  lab manual "Implementation of different types of function"
**Theory lectures this lines up with:** 12–17 (functions)

Use every function family on real data, and use them to build the first three pieces of fraud logic by hand: the z-score (Rule 1), the hour of day (Rule 2) and the distance and speed between cities (Rule 5).

## What was added

| File | What it is |
|---|---|
| `queries/01_number_functions.sql` | ROUND, CEIL, FLOOR, TRUNCATE, MOD, ABS, SQRT, POWER, GREATEST/LEAST, and the Haversine formula from sines and cosines. |
| `queries/02_aggregate_functions.sql` | COUNT, SUM, AVG, MIN, MAX, STDDEV_SAMP, VARIANCE; `COUNT(*)` vs `COUNT(col)`. |
| `queries/03_string_functions.sql` | UPPER, CONCAT, LEFT/RIGHT, SUBSTRING, INSTR, REPLACE, LPAD, TRIM; masking emails and phones. |
| `queries/04_date_functions.sql` | NOW, DATE, HOUR, DAYNAME, DATE_FORMAT, DATE_ADD, DATEDIFF, TIMESTAMPDIFF. |
| `queries/05_rule1_high_amount.sql` | **Rule 1 for one account**, with user variables. |
| `queries/06_rule2_off_hours_preview.sql` | Rule 2 preview using `HOUR()`. |
| `queries/07_rule5_impossible_travel_by_hand.sql` | **Rule 5 for the traveller persona.** |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- Delhi → Chennai = **1767.7 km**. The traveller's 10-minute hop implies **10,606 km/h**, so `IMPOSSIBLE TRAVEL` (limit 900).
- Account 1: average **5,980.49**, standard deviation **12,765.36**. Txn 12052 (₹95,000) has **z = 6.97**.
- The only 00:00-04:59 transaction on account 1 is **12043**.

## Concepts you must be able to explain (viva)

- **Aggregate functions skip NULL.** …except `COUNT(*)`.
- **z-score.** `(x - mean) / standard deviation`: how many deviations from this account's normal. > 3 is unusual **if the data is bell-shaped**.
- **STDDEV_SAMP vs STDDEV_POP.** Sample (÷ n-1) when the rows are a sample of behaviour; population (÷ n) when they are everything. We use sample.
- **Haversine.** Great-circle distance on a sphere (radius 6371 km) from two latitude/longitude pairs.
- **User variables.** `SELECT … INTO @x` carries a value to the next statement. Session-scoped; Week 10 replaces them with `DECLARE`d variables.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout step 8 (advanced SQL: joins and subqueries ahead; functions underpin all rules).

## Results (captured from the running database)

### Evidence: Rule 1 by hand: the 95,000 payment

Script: [`week-05-functions/queries/05_rule1_high_amount.sql`](../../week-05-functions/queries/05_rule1_high_amount.sql)

```text
+------------------+-----------------+
| account1_average | account1_stddev |
+------------------+-----------------+
|          5980.49 |        12765.36 |
+------------------+-----------------+
+--------+----------+---------+-------------------+
| txn_id | amount   | z_score | reason            |
+--------+----------+---------+-------------------+
|  12052 | 95000.00 |    6.97 | High amount (z=7) |
+--------+----------+---------+-------------------+
```

### Evidence: Rule 5 by hand: Delhi to Chennai in 10 minutes

Script: [`week-05-functions/queries/07_rule5_impossible_travel_by_hand.sql`](../../week-05-functions/queries/07_rule5_impossible_travel_by_hand.sql)

```text
+-------------+---------+-------------------+-------------------+
| distance_km | minutes | implied_speed_kmh | verdict           |
+-------------+---------+-------------------+-------------------+
|      1767.7 |      10 |             10606 | IMPOSSIBLE TRAVEL |
+-------------+---------+-------------------+-------------------+
```


---

# Week 6 — Operators: arithmetic, comparison, logical, special, set



**Lab:** Handout lab list **#6 — Operators** (ARITHMETIC, LOGICAL, COMPARISON, SPECIAL, SET)  ·  lab manual "Implementation of different types of operators"
**Theory lectures this lines up with:** 12–17 (operators)

Every operator family on real data, ending in a deliberately naive "first-cut fraud screen" built from fixed thresholds, which shows *why* the later weeks compare each account with its own history.

## What was added

| File | What it is |
|---|---|
| `queries/01_arithmetic_operators.sql` | `+ - * / DIV %`, precedence, division by zero. |
| `queries/02_comparison_operators.sql` | `= <> < > <= >= <=>`; the `= NULL` trap. |
| `queries/03_logical_operators.sql` | AND, OR, NOT, XOR and why brackets matter (1,300 rows vs 148). |
| `queries/04_special_operators.sql` | BETWEEN, IN, NOT IN, LIKE (`%` and `_`), IS NULL, REGEXP. |
| `queries/05_set_operators.sql` | UNION, UNION ALL, INTERSECT, EXCEPT on lists of accounts. |
| `queries/06_first_cut_fraud_screen.sql` | A screen from fixed rules of thumb: **216 transactions caught, only 27 planted**. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- `amount > 5000 AND (status='failed' OR status='pending')` → **148** rows; the same without brackets → **1,300**.
- Accounts with a payment over 50,000: 8. Of those, **only account 20** also made a large night payment (INTERSECT); the other **7** are EXCEPT.
- The first-cut screen returns **216** rows. Most are innocent: the cost of fixed thresholds.

## Concepts you must be able to explain (viva)

- **Precedence.** `NOT` > `AND` > `OR`; `*` `/` before `+` `-`. Brackets remove doubt.
- **NULL logic.** Any comparison with NULL is *unknown*. Use `IS NULL` or `<=>`.
- **BETWEEN.** Inclusive at both ends.
- **LIKE.** `%` = any run of characters, `_` = exactly one.
- **Set operators.** Same number of columns, compatible types. UNION removes duplicates; UNION ALL keeps them. `EXCEPT` = Oracle's `MINUS` (MySQL 8.0.31+).
- **False positives.** Fixed thresholds treat a rich customer's normal payment as fraud. Rule 1 fixes that with a per-account baseline.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout step 8 (advanced SQL).

## Results (captured from the running database)

### Evidence: Set operators

Script: [`week-06-operators/queries/05_set_operators.sql`](../../week-06-operators/queries/05_set_operators.sql)

```text
+------------+
| account_id |
+------------+
|          1 |
|         20 |
|        117 |
|        158 |
|        165 |
+------------+
+--------+
| a_or_b |
+--------+
|     31 |
+--------+
+----------------+
| rows_union_all |
+----------------+
|             32 |
+----------------+
+------------+
| account_id |
+------------+
|         20 |
+------------+
+-------------------+
| big_but_not_night |
+-------------------+
|                 7 |
+-------------------+
+-----------------+--------+------------+
| flagged_because | txn_id | account_id |
+-----------------+--------+------------+
| small hours     |  12043 |          1 |
| big amount      |  12052 |          1 |
+-----------------+--------+------------+
```

### Evidence: First-cut fraud screen

Script: [`week-06-operators/queries/06_first_cut_fraud_screen.sql`](../../week-06-operators/queries/06_first_cut_fraud_screen.sql)

```text
+--------+------------+----------+------+---------+--------------------------------------------+
| txn_id | account_id | amount   | hr   | status  | why                                        |
+--------+------------+----------+------+---------+--------------------------------------------+
|  12052 |          1 | 95000.00 |   11 | success | very large amount, device 999 (never seen) |
|  12059 |        285 | 69888.23 |   18 | success | very large amount                          |
|  12053 |        117 | 66536.48 |   12 | success | very large amount                          |
|  12062 |        165 | 62629.96 |   21 | success | very large amount                          |
|  12061 |        158 | 61521.54 |   20 | success | very large amount                          |
|  12058 |        316 | 60943.44 |   17 | success | very large amount                          |
|  12067 |         20 | 59733.72 |    2 | success | very large amount, large night payment     |
|  12060 |        451 | 51180.91 |   19 | success | very large amount                          |
|  12065 |        358 | 34249.12 |    0 | success | large night payment                        |
|   2821 |         86 | 21238.33 |    4 | success | large night payment                        |
|   1337 |        302 | 15021.19 |    1 | success | large night payment                        |
|   5696 |        481 | 13373.93 |    4 | success | large night payment                        |
|    415 |        283 | 12474.93 |    0 | failed  | large night payment                        |
|   8207 |          7 | 12231.30 |    0 | success | large night payment                        |
|   2516 |        257 | 12205.23 |    4 | success | large night payment                        |
+--------+------------+----------+------+---------+--------------------------------------------+
+-------------+
| screened_in |
+-------------+
|         216 |
+-------------+
```


---

# Week 7 — Joins: inner, outer, natural, self



**Lab:** Handout lab list **#7 — Joins** (INNER, OUTER, NATURAL, SELF)  ·  lab manual "Implementation of different types of Joins"
**Theory lectures this lines up with:** 18–20 (joins)

Combine tables. Joins give the first *real* rules: **Rule 3** (new device) with an anti-join, the first half of **Rule 4** (velocity) with a self-join, and **Rule 5** for every account at once.

## What was added

| File | What it is |
|---|---|
| `queries/01_inner_join.sql` | Seven-table join telling the whole story of the ₹95,000 payment; CROSS JOIN. |
| `queries/02_outer_joins.sql` | LEFT, RIGHT, anti-join (`… IS NULL`), and a FULL OUTER emulation with UNION. |
| `queries/03_natural_join.sql` | NATURAL JOIN, its pitfall, and `USING`. |
| `queries/04_self_join.sql` | Same-first-name users; the velocity pairs for the burst persona. |
| `queries/05_rule3_new_device.sql` | **Rule 3**: transactions on a device the account never used. |
| `queries/06_rule5_impossible_travel_pairs.sql` | **Rule 5 for all accounts** via a self-join. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- Txn 12052 → Tammy Allison, merchant Cline-Ayala, Mumbai, Android 14.
- **434** accounts have never logged in (anti-join). Every device appears in a transaction (0 unused).
- `merchants NATURAL JOIN locations` returns **0** rows: three shared column names must all match.
- The burst persona yields **28** pairs inside 5 minutes (8 transactions → C(8,2)).
- Rule 3 flags **16** transactions: 12052 plus the bad-merchant rows. Rule 5 gives **33** pairs; only the first (account 1, Delhi → Chennai) is the planted one. **32 are noise**, because the seed gives every transaction a random city (`limitations.md` #1).

## Concepts you must be able to explain (viva)

- **Inner vs outer.** Inner keeps only matching pairs. LEFT keeps all left rows (NULLs on the right). RIGHT mirrors it.
- **Anti-join.** `LEFT JOIN … WHERE right.key IS NULL`: "rows with no match".
- **Self join.** The same table twice under two aliases; use `<` or `>` on ids so each pair appears once.
- **Natural join.** Joins on all same-named columns. Fragile; prefer `ON` or `USING`.
- **Join vs subquery.** Same questions can be asked either way; joins read well for combining, subqueries for filtering.
- **Cross join.** Every combination. Forgetting the `ON` clause creates one by accident.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout step 8 (advanced SQL: joins).

## Results (captured from the running database)

### Evidence: Seven-table join: the whole story of one payment

Script: [`week-07-joins/queries/01_inner_join.sql`](../../week-07-joins/queries/01_inner_join.sql)

```text
+--------+---------------+------------+----------+---------------+---------------+----------+-------------+------------+---------------------+
| txn_id | full_name     | account_id | amount   | merchant_name | category_name | txn_city | device_type | os         | txn_time            |
+--------+---------------+------------+----------+---------------+---------------+----------+-------------+------------+---------------------+
|  12052 | Tammy Allison |          1 | 95000.00 | Cline-Ayala   | Fashion       | Mumbai   | mobile      | Android 14 | 2026-08-18 11:00:00 |
+--------+---------------+------------+----------+---------------+---------------+----------+-------------+------------+---------------------+
+--------+---------------+
| txn_id | merchant_name |
+--------+---------------+
|  12052 | Cline-Ayala   |
+--------+---------------+
+---------------------+
| merchants_with_txns |
... (21 more lines)
```

### Evidence: Rule 3: new device

Script: [`week-07-joins/queries/05_rule3_new_device.sql`](../../week-07-joins/queries/05_rule3_new_device.sql)

```text
+--------+------------+-----------+------------------------------------------------------------------+----------+
| txn_id | account_id | device_id | fingerprint_hash                                                 | amount   |
+--------+------------+-----------+------------------------------------------------------------------+----------+
|  12052 |          1 |       999 | NEVER_SEEN_DEVICE_HASH_001                                       | 95000.00 |
|  12053 |        117 |       109 | d95e5209182f0cd4a959c0a71879d0ac7a281c48cd8f1a8b135990a337d64a29 | 66536.48 |
|  12054 |         94 |        82 | 225093b22ba889759761bf9d97bcf7181d20034f4606c086e0383fe9592bd0aa | 41462.45 |
|  12055 |        145 |        19 | e5c3a3eab2dfaa06909c048da252ff9c315b6946a2ab2418bd99c755caeefa94 |  5694.10 |
|  12056 |         77 |        33 | 57aa346d77a61b6a6806beb4e865763f29f8cda2ca2dacfd85d66b217743fcfe | 10559.60 |
|  12057 |        113 |       179 | 00c6a81aef67048beb91e87a3e05d963fd8d8164fb4dcef10564db8417d4ab43 | 43111.67 |
|  12058 |        316 |       165 | 1bf19464968316be77526f96d1d2587088d7fd9e45dea34d12fe8bfc88f80a8c | 60943.44 |
|  12059 |        285 |       104 | 0dfbc86ad6de9296cf92b2c6aec37c777fa94bd1002d5fe2e69ca6ec98b556a3 | 69888.23 |
|  12060 |        451 |       121 | a8690afc851337687f2cf531d35c0da9202f8ba81034fed581ca14e11a110310 | 51180.91 |
|  12061 |        158 |        21 | 24bc87b2b67c30778248ee27be5da0ac0900b605a5704ef06b50bc4c18c4af54 | 61521.54 |
|  12062 |        165 |       127 | 4ac7acc4bedf04dc077aa1267109fbdf8e8547f2a6dd9ecd00baa60c6e98969d | 62629.96 |
|  12063 |         46 |       106 | 4b209ba5b3f5e1e8086576111237a121380aa359ff8a868640bfe5b907ee1070 | 30544.64 |
|  12064 |        260 |       170 | 0fce1eecf97cd45f808ffce56ebe5bf74bb9bf97c31e52adc96d395b5a3af85e | 24191.73 |
|  12065 |        358 |        54 | 51218c513959ae5f3b8a0b18bb6f8f95f3e7e100be943ecb6add03f87ca65353 | 34249.12 |
|  12066 |        495 |       131 | 8cd4347f9935f6687e9aca3a8d373db3f946bd9dd35e6245f2a867dea8b2c8df | 10552.67 |
|  12067 |         20 |        90 | de5c6044071daeda338e6c198d13bc628ba51594662de7839d660d1e21c0eb0a | 59733.72 |
+--------+------------+-----------+------------------------------------------------------------------+----------+
+-------------------------+
| txns_on_unknown_devices |
+-------------------------+
|                      16 |
+-------------------------+
```


---

# Week 8 — GROUP BY, HAVING, ORDER BY — and subqueries



**Lab:** Handout lab list **#8 — GROUP BY, HAVING, ORDER BY**  ·  lab manual Exp 7 (and Exp 9 "Subqueries")
**Theory lectures this lines up with:** 18–20 (group by, having, order by, subqueries)

Aggregate per group and filter groups. The three "statistical" rules are now complete for **every** account at once: Rule 1, Rule 2, Rule 4 (velocity). A stand-in for Rule 6 appears, and the first *permanent* data computed by SQL fills `behaviour_baselines`.

## What was added

| File | What it is |
|---|---|
| `sql/01_compute_baselines.sql` | **Loaded by the build.** One row per account: average, deviation, hours used, cities used (`INSERT … SELECT` with three GROUP BY subqueries). |
| `queries/01_group_by.sql` | Per status, per month, hour-of-day histogram, per account, WITH ROLLUP, GROUP_CONCAT. |
| `queries/02_having.sql` | WHERE vs HAVING; **Rule 4 (velocity) complete**. |
| `queries/03_order_by_limit.sql` | Sorting, LIMIT, OFFSET, several sort keys. |
| `queries/04_subqueries.sql` | Scalar, IN, EXISTS, correlated, derived table, ALL, subquery in SELECT. |
| `queries/05_rule1_high_amount_all_accounts.sql` | **Rule 1 for all accounts.** |
| `queries/06_rule2_off_hours_all_accounts.sql` | **Rule 2 for all accounts.** |
| `queries/07_rule6_merchant_risk.sql` | Rule 6 with a stand-in for "alerted" (the alerts table is still empty). |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- `behaviour_baselines`: **597** rows. Account 1: average 5,980.49, 11 distinct hours, 3 cities.
- Rule 1: **145** transactions with z > 3 across the table; 12052 is the top (6.97). Most are ordinary: amounts are skewed.
- Rule 2: two hits, **12043** (the planted 02:30) and 12030 (a false alarm: one 3 p.m. transaction out of 52).
- Rule 4: exactly **12049, 12050, 12051**, with counts 6, 7, 8.
- Rule 6 stand-in: merchant **50** on top at 7.5× the platform rate; 5 merchants exceed 2×.

## Concepts you must be able to explain (viva)

- **WHERE vs HAVING.** Rows before grouping vs groups after. Only HAVING may hold an aggregate.
- **GROUP BY rule.** Every SELECT column is either grouped or aggregated (`ONLY_FULL_GROUP_BY`).
- **Logical order of a SELECT.** FROM/JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT.
- **Subquery kinds.** Scalar · IN · EXISTS · correlated (re-run per outer row) · derived table (in FROM).
- **NOT IN vs NOT EXISTS.** `NOT IN` returns nothing if the list contains NULL.
- **WITH ROLLUP.** Adds subtotal and grand-total rows.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout step 8 (advanced SQL: joins, subqueries, analytics).

## Results (captured from the running database)

### Evidence: Rule 4 (velocity) complete

Script: [`week-08-groupby-subqueries/queries/02_having.sql`](../../week-08-groupby-subqueries/queries/02_having.sql)

```text
+------------+-----------------+
| account_id | successful_txns |
+------------+-----------------+
|          1 |              52 |
|        154 |              30 |
|        543 |              30 |
+------------+-----------------+
+-------------+------+------------+
| merchant_id | txns | avg_amount |
+-------------+------+------------+
|          50 |  253 |    4378.00 |
+-------------+------+------------+
+------------+--------+---------------------+----------------+
| account_id | txn_id | txn_time            | txns_in_window |
+------------+--------+---------------------+----------------+
|          1 |  12049 | 2026-08-17 14:02:00 |              6 |
|          1 |  12050 | 2026-08-17 14:02:24 |              7 |
|          1 |  12051 | 2026-08-17 14:02:48 |              8 |
+------------+--------+---------------------+----------------+
```

### Evidence: Rule 1 for all accounts

Script: [`week-08-groupby-subqueries/queries/05_rule1_high_amount_all_accounts.sql`](../../week-08-groupby-subqueries/queries/05_rule1_high_amount_all_accounts.sql)

```text
+--------+------------+----------+----------+---------+
| txn_id | account_id | amount   | acct_avg | z_score |
+--------+------------+----------+----------+---------+
|  12052 |          1 | 95000.00 |  5980.49 |    6.97 |
|  12054 |         94 | 41462.45 |  3413.10 |    5.05 |
|  12063 |         46 | 30544.64 |  3131.96 |    4.92 |
|   1263 |        446 | 16317.70 |  2207.29 |    4.58 |
|   4828 |        392 | 14753.36 |  2053.00 |    4.37 |
|   5207 |        399 | 11092.76 |  1632.17 |    4.35 |
|  12059 |        285 | 69888.23 |  5483.09 |    4.33 |
|  12062 |        165 | 62629.96 |  5581.71 |    4.29 |
|   7323 |        405 |  8132.39 |  1323.77 |    4.27 |
|   3517 |        161 | 19012.34 |  2685.69 |    4.26 |
+--------+------------+----------+----------+---------+
```

### Evidence: Rule 6 stand-in

Script: [`week-08-groupby-subqueries/queries/07_rule6_merchant_risk.sql`](../../week-08-groupby-subqueries/queries/07_rule6_merchant_risk.sql)

```text
+-------------+---------------------------+------+---------+-------------------+-------------------+----------------+
| merchant_id | merchant_name             | txns | flagged | merchant_rate_pct | platform_rate_pct | times_platform |
+-------------+---------------------------+------+---------+-------------------+-------------------+----------------+
|          50 | Ramirez and Sons          |  253 |      15 |              5.93 |              0.79 |            7.5 |
|          21 | Chavez-Hall               |  255 |       6 |              2.35 |              0.79 |            3.0 |
|          35 | Anderson Group            |  236 |       5 |              2.12 |              0.79 |            2.7 |
|          11 | Acosta, Garcia and Moreno |  236 |       4 |              1.69 |              0.79 |            2.2 |
|          27 | Aguirre LLC               |  252 |       4 |              1.59 |              0.79 |            2.0 |
+-------------+---------------------------+------+---------+-------------------+-------------------+----------------+
```


---

# Week 9 — Views and indexes (plus DCL: roles, GRANT, REVOKE)



**Lab:** Handout lab list **#8/#9 — Views and Indexes**  ·  lab manual Exp 8 "Indexes" and Exp 9 "Subqueries and Indexes". **DCL is not a numbered lab**, but the mini-project (handout step 7) requires it, and views are the natural place for access control, so it lives here.
**Theory lectures this lines up with:** 18–20 (views); 28–33 (indexing, B+ trees), 21 for security context

Package the eight weeks of queries as named, reusable views, speed up the access paths with measured indexes, and lock the data down with roles. After this week **all five fraud personas are found by SQL views alone**: no trigger yet.

## What was added

| File | What it is |
|---|---|
| `sql/10_rule_views.sql` | The six rule views and `v_transaction_risk`, which adds them up and explains in plain English. |
| `sql/20_reporting_views.sql` | `v_active_alerts`, `v_top_risky_users`, `v_alerts_by_city_day`, `v_daily_txn_summary`. |
| `sql/30_indexes.sql` | Eight indexes, each justified. Two are deliberately *not* created. |
| `sql/40_roles_dcl.sql` | Roles `fraud_analyst`, `txn_app`, `db_admin`; three users; GRANT; default roles. |
| `queries/01_use_the_views.sql` | Using the views; tuning with an UPDATE; switching a rule off. |
| `demo/explain_before_after.sql` | `EXPLAIN ANALYZE` with and without each index (self-restoring). |
| `demo/dcl_demo.sh` | Seven steps from three logins: allowed, denied, REVOKE, re-GRANT, SHOW GRANTS. |
| `docs/benchmark_measured.md` | The real measurements, honestly interpreted. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- 11 views. Rule counts: z-score **145**, off-hours **2**, new device **16**, velocity **3**, impossible travel **46** (consecutive-transaction version), merchant risk **0** (no alerts yet).
- `v_transaction_risk` explains each persona in words, e.g. 12052 → *High amount (z=6.97); New device (NEVER_SE...)*.
- `analyst_user`: allowed on `v_daily_txn_summary`, **denied** (error 1142) on `transactions`. `app_user`: can read `transactions`, denied on `users`.
- Indexes: date-range query cost **1349 → 174** (table scan → index range scan). See `docs/benchmark_measured.md` for why the account index only removes a Sort.

## Concepts you must be able to explain (viva)

- **View.** A stored SELECT with no data of its own. Hides complexity, centralises logic, and is a security boundary.
- **`CREATE OR REPLACE VIEW`.** Redefines a view and keeps its grants.
- **CTE (`WITH`) and `LAG()`.** Beyond the lab list. A CTE is a named subquery for one statement; `LAG(x) OVER (PARTITION BY a ORDER BY t)` reads the previous row of the same group.
- **Index (B+ tree).** A sorted structure that lets MySQL jump to rows. Speeds reads, slows writes, costs space.
- **Composite index.** `(account_id, txn_time)` serves filters on `account_id` and on both, **not** on `txn_time` alone (leftmost-prefix rule).
- **Clustered vs secondary.** InnoDB stores the table as the primary-key B+ tree; every other index is secondary.
- **Role, GRANT, REVOKE.** A role is a named bundle of privileges. Least privilege: give each login only what its job needs.
- **DEFINER rights.** A view runs with its creator's rights, so a role can read a view without reading the tables.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout steps 8, 10 (views; indexing & optimisation) and 7 (DCL).

## Results (captured from the running database)

### Evidence: Index experiment: EXPLAIN ANALYZE

See [`docs/benchmark_measured.md`](../../week-09-views-indexes-dcl/docs/benchmark_measured.md) for the full measured output. Key result:

| Query | Without the index | With the index | Verdict |
|---|---|---|---|
| Date-range report over 6 days (`idx_txn_time`) | **Table scan**, reads all 12,067 rows, optimiser cost **1349** | **Index range scan**, reads only the 315 matching rows, cost **174** | Clear win: about 8x cheaper by cost. |
| Latest 50 transactions of account 1 (`idx_txn_account_time`) | index lookup on `account_id`, **then a Sort** step | index lookup that already returns rows in time order, **no Sort** | Real but tiny: an account has only ~52 rows, so sorting them costs microseconds. It would matter for accounts with millions of rows. |
| Merchant 50, newest 20 (`idx_txn_merchant_time`) | (not measured) | index lookup in reverse time order, stops after 20 rows | Same effect as above. |


---

# Week 10 — Stored procedures, triggers — and transactions



**Lab:** Handout lab list **#9/#10 — Stored Procedures and Triggers**  ·  lectures on PL/SQL and transaction management
**Theory lectures this lines up with:** 21–22 (stored procedures, triggers); 34–42 (transactions, concurrency) for `transfer_funds`

The finale: the same six rules, now as one stored procedure that a trigger runs on every INSERT. Plus a stored function, a nightly event, audit triggers, and an all-or-nothing money transfer. **This is the 90-second demo.**

## What was added

| File | What it is |
|---|---|
| `sql/10_haversine_function.sql` | Stored function `haversine_km()`; the Week 9 travel view is refactored to call it. |
| `sql/20_score_transaction.sql` | `score_transaction(txn_id)` (six rules → `alerts`) and `backfill_alerts(from, to)`. |
| `sql/30_triggers.sql` | `AFTER INSERT` on transactions (score it) · `BEFORE UPDATE` on alerts (stamp `reviewed_at`) · `AFTER UPDATE` on alerts (audit trail). |
| `sql/40_baseline_refresh_and_event.sql` | `refresh_behaviour_baselines()` with transaction + EXIT HANDLER, run nightly by an EVENT. |
| `sql/50_transfer_funds.sql` | ACID money transfer: validation, ordered row locks, COMMIT/ROLLBACK. |
| `sql/60_backfill_personas.sql` | Scores the 27 persona transactions (12041-12067). |
| `demo/01_fraud_demo.sql` | **The 90-second demo**, self-cleaning. |
| `demo/02_transaction_demo.sql · 03_transfer_failures_violation.sql` | Rollback, a good transfer, four refused transfers. |
| `demo/04_concurrency_demo.sh · 05_analyst_workflow.sh` | A real lock wait between two sessions; the system seen from three logins. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- **21 alerts** from the back-fill: traveller 12042 · night-owl 12043 · burst 12049-51 · 12052 (*High amount + New device*) · 12053-12067 at merchant 50, which gain *Merchant risk* from the 4th alert on (12056 onward = 12 alerts).
- Live demo: a ₹95,000 insert at 03:15 from device 999 creates an alert with **3 reasons** by itself; closing it stamps `reviewed_at` and writes an `audit_log` row naming the real user (`analyst_user@localhost`).
- Four bad transfers all refused; total money unchanged; the lock demo blocks the second session for ~5 s.
- Cost: ≈ 2 ms per insert with the trigger vs 0.04 ms without (`week-11…/docs/performance.md`).

## Concepts you must be able to explain (viva)

- **Function vs procedure.** Function: returns one value, used inside SELECT. Procedure: `CALL`ed, can modify data and return result sets.
- **Trigger.** Runs automatically on INSERT/UPDATE/DELETE. BEFORE can edit `NEW`; AFTER sees the stored row. `OLD` and `NEW` are the row before/after.
- **Why the scoring trigger is AFTER.** It reads the row it was fired for.
- **`USER()` vs `CURRENT_USER()` in a trigger.** `CURRENT_USER()` is the trigger's definer (root); `USER()` is the person who connected. Using the wrong one makes an audit trail blame root.
- **ACID.** Atomicity (transfer is all or nothing) · Consistency (no negative balance) · Isolation (`FOR UPDATE` row locks) · Durability (redo log after COMMIT).
- **Deadlock avoidance.** Always lock rows in ascending id order.
- **EXIT HANDLER.** On any SQL error: ROLLBACK, then re-raise.
- **EVENT.** A scheduled job inside MySQL (needs `event_scheduler=ON`).
- **DELIMITER.** A *client* command so the `;` inside a routine body does not end the statement early.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout steps 8 and 9 (procedures, triggers; transaction management).

## Results (captured from the running database)

### Evidence: The 90-second demo

Script: [`week-10-procedures-triggers/demo/01_fraud_demo.sql`](../../week-10-procedures-triggers/demo/01_fraud_demo.sql)

```text
+--------+---------+---------------------+-----------+
| txn_id | amount  | txn_time            | device_id |
+--------+---------+---------------------+-----------+
|  12037 | 5018.20 | 2026-01-06 16:49:00 |       182 |
|  12026 | 5437.25 | 2026-01-06 12:42:00 |       182 |
|  12011 | 4438.22 | 2026-01-06 12:31:00 |       182 |
|  12032 | 2697.77 | 2026-01-06 12:25:00 |       182 |
|  12015 | 6759.35 | 2026-01-06 10:08:00 |       182 |
+--------+---------+---------------------+-----------+
+---------------+
| alerts_before |
+---------------+
|            21 |
+---------------+
+----------+--------+------------+-------------------------------------------------------------------------------------------------+--------+
| alert_id | txn_id | risk_score | reasons                                                                                         | status |
+----------+--------+------------+-------------------------------------------------------------------------------------------------+--------+
|       27 |  12076 |       3.00 | ["High amount (z=4.97)", "Off-hours (3:00, only 1.89% of history)", "New device (NEVER_SE...)"] | open   |
+----------+--------+------------+-------------------------------------------------------------------------------------------------+--------+
+-----------+---------------------+
| status    | reviewed_at         |
+-----------+---------------------+
| confirmed | 2026-10-08 02:12:20 |
+-----------+---------------------+
+------------+-----------+--------------------+-------------------------+----------------+
| table_name | record_id | old_value_json     | new_value_json          | changed_by     |
+------------+-----------+--------------------+-------------------------+----------------+
| alerts     |        27 | {"status": "open"} | {"status": "confirmed"} | root@localhost |
+------------+-----------+--------------------+-------------------------+----------------+
+-------------------------------------------------------------------------+
| reasons                                                                 |
+-------------------------------------------------------------------------+
| ["Off-hours (3:00, only 1.89% of history)", "New device (NEVER_SE...)"] |
+-------------------------------------------------------------------------+
+-------------------------------------------------------------------------------------------------+
| reasons                                                                                         |
+-------------------------------------------------------------------------------------------------+
| ["High amount (z=4.97)", "Off-hours (3:00, only 1.89% of history)", "New device (NEVER_SE...)"] |
+-------------------------------------------------------------------------------------------------+
+--------+------------+---------------------------------+
| txn_id | risk_score | reasons                         |
+--------+------------+---------------------------------+
|  12082 |       1.00 | ["Velocity spike (6 in 5 min)"] |
+--------+------------+---------------------------------+
+--------------+
| alerts_after |
+--------------+
|           21 |
+--------------+
```

### Evidence: Transactions: rollback and transfer_funds

Script: [`week-10-procedures-triggers/demo/02_transaction_demo.sql`](../../week-10-procedures-triggers/demo/02_transaction_demo.sql)

```text
+------------+-----------+
| account_id | balance   |
+------------+-----------+
|          2 |  30547.83 |
|          3 | 221867.47 |
+------------+-----------+
+--------------------+
| inside_transaction |
+--------------------+
|           30047.83 |
+--------------------+
+----------------+
| after_rollback |
+----------------+
|       30547.83 |
+----------------+
+--------------------+---------+--------------------+----------------------+
| result             | amount  | sender_balance_now | receiver_balance_now |
+--------------------+---------+--------------------+----------------------+
| Transfer completed | 1000.00 |           29547.83 |            222867.47 |
+--------------------+---------+--------------------+----------------------+
+------------+-----------+
| account_id | balance   |
+------------+-----------+
|          2 |  29547.83 |
|          3 | 222867.47 |
+------------+-----------+
+--------+------------+---------+
| txn_id | account_id | amount  |
+--------+------------+---------+
|  12083 |          2 | 1000.00 |
+--------+------------+---------+
+------------+-----------+
| account_id | balance   |
+------------+-----------+
|          2 |  30547.83 |
|          3 | 221867.47 |
+------------+-----------+
```

### Evidence: Refused transfers (errors are the expected result)

Script: [`week-10-procedures-triggers/demo/03_transfer_failures_violation.sql`](../../week-10-procedures-triggers/demo/03_transfer_failures_violation.sql)

```text
+--------------------+
| total_money_before |
+--------------------+
|       154342682.58 |
+--------------------+
+-------------------+
| total_money_after |
+-------------------+
|      154342682.58 |
+-------------------+
+--------------------+
| transactions_added |
+--------------------+
|                  0 |
+--------------------+
ERROR 1644 (45000) at line 6: Insufficient funds
ERROR 1644 (45000) at line 7: Transfer amount must be positive
ERROR 1644 (45000) at line 8: Cannot transfer to the same account
ERROR 1644 (45000) at line 9: Source or destination account does not exist
```


---
