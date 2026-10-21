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
