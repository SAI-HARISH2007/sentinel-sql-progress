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
