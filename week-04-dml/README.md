# Week 4 — DML: INSERT, UPDATE, DELETE, SELECT

[← Week 3](../week-03-constraints/README.md) · [Project README](../README.md) · [Week 5 →](../week-05-functions/README.md)

**Lab:** Handout lab list **#4 — Data Manipulation Language** (SELECT, INSERT, UPDATE, DELETE)  ·  lab manual "Experiment 3: DML COMMANDS"
**Theory lectures this lines up with:** 12–17 (basic SQL: DML)

Put data in. The detector's thresholds go into `rule_config`, and a deterministic generator loads 500 users, 12,067 transactions and five planted fraud personas. From now on every week queries the same data.

## What you add this week

| File | What it is |
|---|---|
| `sql/10_rule_config.sql` | 8 tuning rows (z-score limit, velocity limit, …). The detector will read these; changing them is an UPDATE. |
| `sql/20_seed_data.sql` | The generated data set. **Committed**, so nobody needs Python to build the project. |
| `seed/generate.py` | The generator (Faker, fixed random seed). Re-run only if you want different data. |
| `demo/dml_tour.sql` | Single-row, multi-row and `INSERT … SELECT`; UPDATE; DELETE; a CASCADE; self-cleaning. |
| `lab-practice/dml_employee.sql` | **The manual's 9-question DML assignment (EMPLOYEE table), solved.** |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.

## Run it

```bash
scripts/build.sh 4 && scripts/check.sh 4        # about 20 seconds
docker exec -i sentinel-db mysql -uroot -psentinel_root_2026 sentinel < week-04-dml/demo/dml_tour.sql
```

(Without Docker: set `DB_HOST=127.0.0.1` and use your own MySQL 8; see the project README.)

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

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../docs/LAB_EXAM_CHEATSHEET.md).

## Try it yourself

1. Do `lab-practice/dml_employee.sql` **by hand, closed book**.
2. Write an `UPDATE` that makes account 1 a `'frozen'` account, then undo it.
3. Read the `PERSONA` section of `seed/generate.py`: you will meet these rows in every later week.

## Watch out

- The generator differs from the first version of the project in one place: account 1 receives **no random background traffic** (see `CHANGES_FROM_ORIGINAL.md` #4). Otherwise the night-owl persona can never fire.
- `users.created_at` in the seed depends on today's date if you regenerate. The committed file is fixed.
- Do not load this seed *after* installing the Week 10 trigger: scoring 12,000 rows one by one takes minutes.

## Where this goes in the final report

Handout step 7 (SQL implementation: DML) and step 11 (test data).

## Push checklist

Exact commands for this week are in [`GIT_COMMANDS.md`](../GIT_COMMANDS.md) (section "Week 4"). Commit message: `Week 4: DML — rule_config, seed data (12,067 transactions + 5 fraud personas), lab practice`.
Tick Week 4 in [`PROGRESS.md`](../PROGRESS.md) with the **real** date.

> **If your lab teaches this topic in a different order,** keep the folder but change when you push it. Each week's SQL depends only on earlier weeks (Weeks 2→3 and 4→5+ are the only hard dependencies).
