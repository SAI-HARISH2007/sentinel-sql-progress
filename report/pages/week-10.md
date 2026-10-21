# Week 10 — Stored procedures, triggers — and transactions



**Lab:** Handout lab list **#9/#10 — Stored Procedures and Triggers**  ·  lectures on PL/SQL and transaction management
**Theory lectures this lines up with:** 21–22 (stored procedures, triggers); 34–42 (transactions, concurrency) for `transfer_funds`

The finale: the same six rules, now as one stored procedure that a trigger runs on every INSERT. Plus a stored function, a nightly event, audit triggers, and an all-or-nothing money transfer. **This is the 90-second demo.**

## What was added

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

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout steps 8 and 9 (procedures, triggers; transaction management).

## Results (captured from the running database)

### Evidence: The 90-second demo

Script: [`week-10-procedures-triggers/demo/01_fraud_demo.sql`](../../week-10-procedures-triggers/demo/01_fraud_demo.sql)

```text
+--------+---------+---------------------+-----------+
| txn_id | amount  | txn_time            | device_id |
+--------+---------+---------------------+-----------+
|  12037 | 5018.20 | 2026-01-06 16:49:00 |       182 |
|  12026 | 5437.25 | 2026-01-06 12:42:00 |       182 |
|  12011 | 4438.22 | 2026-01-06 12:31:00 |       182 |
|  12032 | 2697.77 | 2026-01-06 12:25:00 |       182 |
|  12015 | 6759.35 | 2026-01-06 10:08:00 |       182 |
+--------+---------+---------------------+-----------+
+---------------+
| alerts_before |
+---------------+
|            21 |
+---------------+
+----------+--------+------------+-------------------------------------------------------------------------------------------------+--------+
| alert_id | txn_id | risk_score | reasons                                                                                         | status |
+----------+--------+------------+-------------------------------------------------------------------------------------------------+--------+
|       27 |  12076 |       3.00 | ["High amount (z=4.97)", "Off-hours (3:00, only 1.89% of history)", "New device (NEVER_SE...)"] | open   |
+----------+--------+------------+-------------------------------------------------------------------------------------------------+--------+
+-----------+---------------------+
| status    | reviewed_at         |
+-----------+---------------------+
| confirmed | 2026-10-08 02:12:20 |
+-----------+---------------------+
+------------+-----------+--------------------+-------------------------+----------------+
| table_name | record_id | old_value_json     | new_value_json          | changed_by     |
+------------+-----------+--------------------+-------------------------+----------------+
| alerts     |        27 | {"status": "open"} | {"status": "confirmed"} | root@localhost |
+------------+-----------+--------------------+-------------------------+----------------+
+-------------------------------------------------------------------------+
| reasons                                                                 |
+-------------------------------------------------------------------------+
| ["Off-hours (3:00, only 1.89% of history)", "New device (NEVER_SE...)"] |
+-------------------------------------------------------------------------+
+-------------------------------------------------------------------------------------------------+
| reasons                                                                                         |
+-------------------------------------------------------------------------------------------------+
| ["High amount (z=4.97)", "Off-hours (3:00, only 1.89% of history)", "New device (NEVER_SE...)"] |
+-------------------------------------------------------------------------------------------------+
+--------+------------+---------------------------------+
| txn_id | risk_score | reasons                         |
+--------+------------+---------------------------------+
|  12082 |       1.00 | ["Velocity spike (6 in 5 min)"] |
+--------+------------+---------------------------------+
+--------------+
| alerts_after |
+--------------+
|           21 |
+--------------+
```

### Evidence: Transactions: rollback and transfer_funds

Script: [`week-10-procedures-triggers/demo/02_transaction_demo.sql`](../../week-10-procedures-triggers/demo/02_transaction_demo.sql)

```text
+------------+-----------+
| account_id | balance   |
+------------+-----------+
|          2 |  30547.83 |
|          3 | 221867.47 |
+------------+-----------+
+--------------------+
| inside_transaction |
+--------------------+
|           30047.83 |
+--------------------+
+----------------+
| after_rollback |
+----------------+
|       30547.83 |
+----------------+
+--------------------+---------+--------------------+----------------------+
| result             | amount  | sender_balance_now | receiver_balance_now |
+--------------------+---------+--------------------+----------------------+
| Transfer completed | 1000.00 |           29547.83 |            222867.47 |
+--------------------+---------+--------------------+----------------------+
+------------+-----------+
| account_id | balance   |
+------------+-----------+
|          2 |  29547.83 |
|          3 | 222867.47 |
+------------+-----------+
+--------+------------+---------+
| txn_id | account_id | amount  |
+--------+------------+---------+
|  12083 |          2 | 1000.00 |
+--------+------------+---------+
+------------+-----------+
| account_id | balance   |
+------------+-----------+
|          2 |  30547.83 |
|          3 | 221867.47 |
+------------+-----------+
```

### Evidence: Refused transfers (errors are the expected result)

Script: [`week-10-procedures-triggers/demo/03_transfer_failures_violation.sql`](../../week-10-procedures-triggers/demo/03_transfer_failures_violation.sql)

```text
+--------------------+
| total_money_before |
+--------------------+
|       154342682.58 |
+--------------------+
+-------------------+
| total_money_after |
+-------------------+
|      154342682.58 |
+-------------------+
+--------------------+
| transactions_added |
+--------------------+
|                  0 |
+--------------------+
ERROR 1644 (45000) at line 6: Insufficient funds
ERROR 1644 (45000) at line 7: Transfer amount must be positive
ERROR 1644 (45000) at line 8: Cannot transfer to the same account
ERROR 1644 (45000) at line 9: Source or destination account does not exist
```


---
