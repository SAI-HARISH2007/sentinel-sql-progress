# What changed from the first version (`sentinel-sql`) — and the evidence

The first version was a single drop. Restructuring it by week meant running everything on a real MySQL 8.4.11 for the first time end-to-end. This file lists what that found. Every item was observed, not assumed.

## Bugs in the original
| # | Problem | Evidence | Fix |
|---|---|---|---|
| 1 | `03_procedures_triggers_events.sql` **aborts** on `JSON_ARRAYAGG(DISTINCT …)`, which MySQL does not support. The `mysql` client stops at the first error, so the **nightly event and the audit trigger were never created**. | `ERROR 1064` at line 171; afterwards only `trg_after_txn_insert` and no events existed. | Distinct values taken in an inner subquery (wk 8, wk 10). |
| 2 | Loading the seed **with the scoring trigger active** is extremely slow. | After 250 s only 5,925 of 12,067 rows were in. | Trigger installed last (wk 10); weeks 1-9 build in ~20 s. |
| 3 | `docs/er-diagram.dbml` described a different schema (enum values `credit`, `completed`, `investigating`… that do not exist). | Compared with `01_schema.sql`. | ER docs are now **generated** from the real schema (`scripts/gen_er_docs.py`). |
| 4 | The **night-owl persona could never fire**: account 1 also got ~24 random-hour transactions, so 02:xx held 3 of 64 (4.7 %) vs the 2 % limit. | Hour histogram of account 1. | Account 1 gets no background traffic (`seed/generate.py`); now 1/52 = 1.92 %. |
| 5 | `audit_log.changed_by` recorded `root@localhost` for every change, because `CURRENT_USER()` inside a trigger is the definer. | Closed an alert as `analyst_user`; log said root. | `USER()`; now `analyst_user@localhost`. |
| 6 | The analyst role could not close alerts: `UPDATE (status, reviewed_at)` without `SELECT` on the WHERE column. | `ERROR 1143` reproduced. | Column-level SELECT added. |
| 7 | `docs/benchmark.md` contained hand-written "expected" numbers presented as results. | The text says "Expected". | Replaced with measured `EXPLAIN ANALYZE` (wk 9). Real result: ≈ 8× cheaper for range scans, but only a removed Sort for per-account lookups. |
| 8 | Rule 6 flagged every transaction of any merchant with a *single* alert (1,698 rows once alerts existed). | `SELECT COUNT(*) FROM rule_merchant_risk` | New setting `merchant_risk_min_alerts = 3`. |
| 9 | The test suite accepted `risk_score >= 1` for any rule, so it could not tell which rule fired. | Read `tests/test_rules.py`. | Tests assert the specific reason text. |

## Design changes (not bugs)
* Views respect `rule_config.enabled` like the procedure does.
* `score_transaction` uses `DECLARE`d variables instead of `@session` variables; same logic as the views.
* Two redundant indexes dropped (`alerts(txn_id)`, `behaviour_baselines(account_id)`: already `UNIQUE`).
* `transfer_funds`: validates first, locks rows in ascending id order (deadlock-free), records only the sender's debit.
* Three extra CHECK constraints (balance ≥ 0, latitude, longitude ranges).
* `refresh_behaviour_baselines()` wraps the nightly job in a transaction with an EXIT HANDLER.
* Client charset forced to utf8mb4 (a latin1 client broke view comparisons).

## Unchanged
Table and column names, the six rules' ideas, the persona scenarios, the three roles, the Docker setup (now MySQL 8.4).
