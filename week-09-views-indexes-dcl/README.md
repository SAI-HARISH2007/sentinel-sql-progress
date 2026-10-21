# Week 9 — Views and indexes (plus DCL: roles, GRANT, REVOKE)

[← Week 8](../week-08-groupby-subqueries/README.md) · [Project README](../README.md) · [Week 10 →](../week-10-procedures-triggers/README.md)

**Lab:** Handout lab list **#8/#9 — Views and Indexes**  ·  lab manual Exp 8 "Indexes" and Exp 9 "Subqueries and Indexes". **DCL is not a numbered lab**, but the mini-project (handout step 7) requires it, and views are the natural place for access control, so it lives here.
**Theory lectures this lines up with:** 18–20 (views); 28–33 (indexing, B+ trees), 21 for security context

Package the eight weeks of queries as named, reusable views, speed up the access paths with measured indexes, and lock the data down with roles. After this week **all five fraud personas are found by SQL views alone**: no trigger yet.

## What you add this week

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

## Run it

```bash
scripts/build.sh 9 && scripts/check.sh 9
docker exec -i sentinel-db mysql -uroot -psentinel_root_2026 -t sentinel < week-09-views-indexes-dcl/queries/01_use_the_views.sql
bash week-09-views-indexes-dcl/demo/dcl_demo.sh
```

(Without Docker: set `DB_HOST=127.0.0.1` and use your own MySQL 8; see the project README.)

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

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../docs/LAB_EXAM_CHEATSHEET.md).

## Try it yourself

1. Run `EXPLAIN SELECT …` on a query that filters by `txn_time` only, then by `account_id` only. Which index does each use?
2. `REVOKE` one privilege from `fraud_analyst`, log in as the analyst, watch the error, `GRANT` it back.
3. Why do the Week 7 pair-join (33) and the Week 9 view (46) disagree on impossible travel? (README of Week 7 + SQL comment).

## Watch out

- Views and the 'lab' definition: the lab only needs `CREATE VIEW … AS SELECT`; the `WITH`/`LAG` views here are extra credit. Be ready to explain every line of whichever view you show.
- A view with an `ORDER BY` inside is not guaranteed to come out sorted when queried; sort in the outer query.
- The two removed indexes (`alerts(txn_id)`, `behaviour_baselines(account_id)`) are redundant with their UNIQUE keys.

## Where this goes in the final report

Handout steps 8, 10 (views; indexing & optimisation) and 7 (DCL).

## Push checklist

Exact commands for this week are in [`GIT_COMMANDS.md`](../GIT_COMMANDS.md) (section "Week 9"). Commit message: `Week 9: views (6 rules + combined + reports), indexes with measured EXPLAIN, DCL roles`.
Tick Week 9 in [`PROGRESS.md`](../PROGRESS.md) with the **real** date.

> **If your lab teaches this topic in a different order,** keep the folder but change when you push it. Each week's SQL depends only on earlier weeks (Weeks 2→3 and 4→5+ are the only hard dependencies).
