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
