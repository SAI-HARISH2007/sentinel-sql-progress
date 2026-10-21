# Week 3 — Constraints: PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, DEFAULT, CHECK

[← Week 2](../week-02-ddl/README.md) · [Project README](../README.md) · [Week 4 →](../week-04-dml/README.md)

**Lab:** Handout lab list **#3 — Constraints** (PRIMARY KEY, FOREIGN KEY, UNIQUE, NULL, NOT NULL, DEFAULT, CHECK, DROP)  ·  lab manual "Constraints"
**Theory lectures this lines up with:** 12–17 (keys, constraints); 23–25 (normalization) for `docs/normalization.md`

Turn the bare tables into a self-defending schema. Every rule is added with `ALTER TABLE` in the order the manual lists them, so you can see each constraint appear.

## What you add this week

| File | What it is |
|---|---|
| `sql/01_constraints.sql` | Primary keys (+ AUTO_INCREMENT), NOT NULL, UNIQUE, DEFAULT, CHECK, FOREIGN KEY with ON DELETE rules. |
| `demo/constraint_violations.sql` | Makes every constraint fire: six statements that **must fail**, with the exact MySQL error code, plus one CASCADE that succeeds. |
| `demo/drop_and_readd_constraints.sql` | The manual's *DROP* part: drop and restore a CHECK, a FOREIGN KEY, a UNIQUE and a DEFAULT. |
| `docs/normalization.md` | The 1NF / 2NF / 3NF / BCNF argument, table by table. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.

## Run it

```bash
scripts/build.sh 3 && scripts/check.sh 3
docker exec -i sentinel-db mysql -uroot -psentinel_root_2026 --force sentinel < week-03-constraints/demo/constraint_violations.sql
```

(Without Docker: set `DB_HOST=127.0.0.1` and use your own MySQL 8; see the project README.)

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

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../docs/LAB_EXAM_CHEATSHEET.md).

## Try it yourself

1. Predict the error code **before** running each line of `constraint_violations.sql`.
2. Add a CHECK that `risk_score` stays between 0 and 100 (`ALTER TABLE merchants ADD CONSTRAINT … CHECK (…)`), then drop it.
3. Prove 3NF for `transactions` in two sentences (Q7 in `week-11…/docs/viva_questions.md`).

## Watch out

- `ALTER COLUMN … SET DEFAULT` keeps the rest of the column; `MODIFY` replaces the *whole* definition. Forget `NOT NULL` in a `MODIFY` and you silently remove it.
- Your lab may teach DML before constraints (the manual's order) or after (the handout's). Both orders work: the constraints here do not depend on data.

## Where this goes in the final report

Handout steps 6-7 (schema design, normalisation; SQL implementation).

## Push checklist

Exact commands for this week are in [`GIT_COMMANDS.md`](../GIT_COMMANDS.md) (section "Week 3"). Commit message: `Week 3: constraints — PK, FK, UNIQUE, NOT NULL, DEFAULT, CHECK, violation demos`.
Tick Week 3 in [`PROGRESS.md`](../PROGRESS.md) with the **real** date.

> **If your lab teaches this topic in a different order,** keep the folder but change when you push it. Each week's SQL depends only on earlier weeks (Weeks 2→3 and 4→5+ are the only hard dependencies).
