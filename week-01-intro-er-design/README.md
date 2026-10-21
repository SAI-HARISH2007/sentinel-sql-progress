# Week 1 — Introduction to MySQL & database design (ER)

[Project README](../README.md) · [Week 2 →](../week-02-ddl/README.md)

**Lab:** Handout lab list **#1 — Introduction to MySQL and ER Diagram**  ·  lab manual **Experiment 0/1 — Introduction to SQL & MySQL and Database Design**
**Theory lectures this lines up with:** 1–9 (introduction to databases, ER modelling, ER → relational design)

Design before you build. You create the empty `sentinel` database and, more importantly, write down the problem, the requirements, the ER diagram and the rules that turn that diagram into tables. No table exists yet.

## What you add this week

| File | What it is |
|---|---|
| `sql/01_create_database.sql` | `DROP/CREATE DATABASE sentinel`, utf8mb4. Every later week starts from this. |
| `docs/problem-statement.md` | Handout steps 1-4: title, problem, objectives, functional + non-functional requirements, the six fraud signals. |
| `docs/er-diagram.md · er-diagram.dbml` | The ER diagram (Mermaid, renders on GitHub) and DBML for dbdiagram.io. **Generated from the real schema**, never hand-edited. |
| `docs/er-to-relational.md` | Which ER-to-tables rule produced which table (strong entity, 1:N, M:N, 1:1, participation, derived attribute). |
| `demo/01_mysql_basics.sql` | `SHOW DATABASES`, `USE`, `SHOW TABLES`, `VERSION()`: the commands in the lab manual's intro page. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.

## Run it

```bash
make up                              # start MySQL in Docker (first time only)
scripts/build.sh 1                   # create the database
scripts/check.sh 1                   # 2 assertions
docker exec -i sentinel-db mysql -uroot -psentinel_root_2026 < week-01-intro-er-design/demo/01_mysql_basics.sql
```

(Without Docker: set `DB_HOST=127.0.0.1` and use your own MySQL 8; see the project README.)

## What you should see

- `SHOW DATABASES` lists `sentinel`; `SHOW TABLES` is empty (tables arrive in Week 2).
- Character set `utf8mb4`, collation `utf8mb4_unicode_ci`.

## Concepts you must be able to explain (viva)

- **DBMS vs file system.** A DBMS adds integrity rules, concurrent access control, security and data independence that plain files lack.
- **The five parts of SQL.** DDL (structure) · DML (change data) · DRL (SELECT) · TCL (COMMIT/ROLLBACK) · DCL (GRANT/REVOKE). The lab manual lists exactly these five.
- **ER vocabulary.** Entity, entity set, attribute (simple/composite/multivalued/derived), relationship, cardinality (1:1, 1:N, M:N), participation (total/partial), weak entity.
- **ER → relational.** Read `docs/er-to-relational.md` twice. Each row is a Part B/C exam answer.
- **Why surrogate keys.** `email`, `fingerprint_hash` are candidate keys; a small `INT` id is the primary key because it is compact in every foreign key and index.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../docs/LAB_EXAM_CHEATSHEET.md).

## Try it yourself

1. **Draw the ER diagram by hand in the notation your faculty uses** (rectangles, ellipses, diamonds). The generated diagram is a reference, not your answer.
2. The lab manual's own ER exercise is *Prescriptions-R-X* (pharmacy, doctors, patients, drugs, contracts). Do it using the same rules as `er-to-relational.md`.
3. For each requirement FR-1…FR-7 write one sentence: which table(s) make it possible?

## Watch out

- Do not copy `er-diagram.md` as your lab answer: the lab wants a hand-drawn diagram in class notation.
- If your lab numbers this experiment 0 and the next one 1, nothing changes here; only the label.

## Where this goes in the final report

Handout steps 1-5 (title, problem, objectives, requirements, ER model).

## Push checklist

Exact commands for this week are in [`GIT_COMMANDS.md`](../GIT_COMMANDS.md) (section "Week 1"). Commit message: `Week 1: problem statement, ER design, create database`.
Tick Week 1 in [`PROGRESS.md`](../PROGRESS.md) with the **real** date.

> **If your lab teaches this topic in a different order,** keep the folder but change when you push it. Each week's SQL depends only on earlier weeks (Weeks 2→3 and 4→5+ are the only hard dependencies).
