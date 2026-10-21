# Week 10 — Stored procedures, triggers — and transactions

[← Week 9](../week-09-views-indexes-dcl/README.md) · [Project README](../README.md) · [Week 11 →](../week-11-final-polish/README.md)

**Lab:** Handout lab list **#9/#10 — Stored Procedures and Triggers**  ·  lectures on PL/SQL and transaction management
**Theory lectures this lines up with:** 21–22 (stored procedures, triggers); 34–42 (transactions, concurrency) for `transfer_funds`

The finale: the same six rules, now as one stored procedure that a trigger runs on every INSERT. Plus a stored function, a nightly event, audit triggers, and an all-or-nothing money transfer. **This is the 90-second demo.**

## What you add this week

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

## Run it

```bash
scripts/build.sh 10 && scripts/check.sh 10
docker exec -i sentinel-db mysql -uroot -psentinel_root_2026 -t sentinel < week-10-procedures-triggers/demo/01_fraud_demo.sql
bash week-10-procedures-triggers/demo/04_concurrency_demo.sh
bash week-10-procedures-triggers/demo/05_analyst_workflow.sh
```

(Without Docker: set `DB_HOST=127.0.0.1` and use your own MySQL 8; see the project README.)

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

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../docs/LAB_EXAM_CHEATSHEET.md).

## Try it yourself

1. Insert a burst of 6 payments for account 5 within two minutes. Which alert appears on the 6th? Delete them afterwards.
2. Disable one rule (`UPDATE rule_config SET enabled = FALSE …`), re-score, watch its reason disappear.
3. Write a trigger that prevents deleting an alert (`SIGNAL SQLSTATE '45000'`). Test it. Drop it.

## Watch out

- Never load bulk data with the trigger installed: scoring 12,000 rows one by one is slow. That is why the trigger is the *last* thing built.
- `CALL backfill_alerts(1, 12067)` takes 38 s and creates 634 alerts: valid, but it buries the story. We only back-fill the personas.
- In a stored routine use `DECLARE`d variables, not `@x`: session variables leak between calls.

## Where this goes in the final report

Handout steps 8 and 9 (procedures, triggers; transaction management).

## Push checklist

Exact commands for this week are in [`GIT_COMMANDS.md`](../GIT_COMMANDS.md) (section "Week 10"). Commit message: `Week 10: stored function/procedures, triggers, event, transfer_funds — fraud detection is live`.
Tick Week 10 in [`PROGRESS.md`](../PROGRESS.md) with the **real** date.

> **If your lab teaches this topic in a different order,** keep the folder but change when you push it. Each week's SQL depends only on earlier weeks (Weeks 2→3 and 4→5+ are the only hard dependencies).
