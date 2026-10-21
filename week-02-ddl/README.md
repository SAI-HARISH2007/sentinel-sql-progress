# Week 2 — DDL: CREATE, ALTER, DROP, TRUNCATE, RENAME

[← Week 1](../week-01-intro-er-design/README.md) · [Project README](../README.md) · [Week 3 →](../week-03-constraints/README.md)

**Lab:** Handout lab list **#2 — Data Definition Language** (CREATE, ALTER, DROP, TRUNCATE, RENAME)  ·  lab manual **"Experiment 2: DDL COMMANDS"** (its index calls it Experiment 1)
**Theory lectures this lines up with:** 12–17 (basic SQL: DDL)

Create all 13 tables with columns and data types only. Four things are created deliberately wrong so the ALTER / RENAME commands have real work to do. No keys, no defaults: that is next week.

## What you add this week

| File | What it is |
|---|---|
| `sql/01_create_tables.sql` | 13 `CREATE TABLE` statements: columns and types, nothing else. |
| `sql/02_alter_tables.sql` | `ADD COLUMN`, `RENAME COLUMN`, `MODIFY`, `DROP COLUMN`, `RENAME TABLE`, each fixing one deliberate flaw. |
| `demo/ddl_tour.sql` | Every DDL command from the manual on a throw-away copy (`CREATE TABLE … LIKE`), cleaned up afterwards. |
| `lab-practice/ddl_employee.sql` | **The lab manual's 9-question DDL assignment (EMPLOYEE table), solved in MySQL**, in its own `lab_practice` database. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.

## Run it

```bash
scripts/build.sh 2 && scripts/check.sh 2
docker exec -i sentinel-db mysql -uroot -psentinel_root_2026 sentinel < week-02-ddl/demo/ddl_tour.sql
docker exec -i sentinel-db mysql -uroot -psentinel_root_2026 < week-02-ddl/lab-practice/ddl_employee.sql
```

(Without Docker: set `DB_HOST=127.0.0.1` and use your own MySQL 8; see the project README.)

## What you should see

- 13 tables (`SHOW TABLES`). `DESCRIBE users` has `date_of_birth` right after `phone`, and the `Key` column is **empty** for every table.
- `devices.fingerprint_hash` is `varchar(64)`; `merchants.merchant_name` is `varchar(200)`; `fraud_alerts` is now called `alerts` and has no `notes` column.

## Concepts you must be able to explain (viva)

- **Data types.** `INT`, `BIGINT`, `DECIMAL(p,s)` (exact: use for money, never FLOAT), `CHAR` vs `VARCHAR`, `TEXT`, `ENUM`, `JSON`, `TIMESTAMP`, `BOOLEAN` (= `TINYINT(1)`).
- **ALTER TABLE.** `ADD`, `MODIFY` (change type/width), `RENAME COLUMN`, `DROP COLUMN`.
- **DELETE vs TRUNCATE vs DROP.** DELETE: chosen rows, can roll back, fires triggers. TRUNCATE: all rows, DDL, resets AUTO_INCREMENT, no rollback. DROP: rows *and* table.
- **DDL commits implicitly.** You cannot ROLLBACK a CREATE/ALTER/DROP/TRUNCATE.
- **Why bare tables first?.** A table without keys is legal but unsafe: it would accept duplicate users and orphan transactions. Week 3 shows the fix.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../docs/LAB_EXAM_CHEATSHEET.md).

## Try it yourself

1. Do `lab-practice/ddl_employee.sql` **by hand, closed book**, then compare. The lab exam is closed book.
2. `SHOW CREATE TABLE devices;` before and after `02_alter_tables.sql`.
3. Try the manual's Oracle syntax (`MODIFY (col …)`) on purpose and read the error. See `docs/LAB_EXAM_CHEATSHEET.md`.

## Watch out

- The manual's `ALTER … MODIFY (col type)` and `DROP COLUMN (col)` **fail in MySQL**: no brackets.
- `VARCHAR2` is Oracle. `S.No` is not a legal column name (`S_No`).
- Re-running `01_create_tables.sql` on an existing database errors with "table exists". Use `scripts/build.sh 2` to start clean.

## Where this goes in the final report

Handout step 7 (SQL implementation: DDL).

## Push checklist

Exact commands for this week are in [`GIT_COMMANDS.md`](../GIT_COMMANDS.md) (section "Week 2"). Commit message: `Week 2: DDL — create 13 tables, ALTER/RENAME/DROP COLUMN, lab practice`.
Tick Week 2 in [`PROGRESS.md`](../PROGRESS.md) with the **real** date.

> **If your lab teaches this topic in a different order,** keep the folder but change when you push it. Each week's SQL depends only on earlier weeks (Weeks 2→3 and 4→5+ are the only hard dependencies).
