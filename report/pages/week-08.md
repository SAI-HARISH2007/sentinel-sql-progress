# Week 8 — GROUP BY, HAVING, ORDER BY — and subqueries



**Lab:** Handout lab list **#8 — GROUP BY, HAVING, ORDER BY**  ·  lab manual Exp 7 (and Exp 9 "Subqueries")
**Theory lectures this lines up with:** 18–20 (group by, having, order by, subqueries)

Aggregate per group and filter groups. The three "statistical" rules are now complete for **every** account at once: Rule 1, Rule 2, Rule 4 (velocity). A stand-in for Rule 6 appears, and the first *permanent* data computed by SQL fills `behaviour_baselines`.

## What was added

| File | What it is |
|---|---|
| `sql/01_compute_baselines.sql` | **Loaded by the build.** One row per account: average, deviation, hours used, cities used (`INSERT … SELECT` with three GROUP BY subqueries). |
| `queries/01_group_by.sql` | Per status, per month, hour-of-day histogram, per account, WITH ROLLUP, GROUP_CONCAT. |
| `queries/02_having.sql` | WHERE vs HAVING; **Rule 4 (velocity) complete**. |
| `queries/03_order_by_limit.sql` | Sorting, LIMIT, OFFSET, several sort keys. |
| `queries/04_subqueries.sql` | Scalar, IN, EXISTS, correlated, derived table, ALL, subquery in SELECT. |
| `queries/05_rule1_high_amount_all_accounts.sql` | **Rule 1 for all accounts.** |
| `queries/06_rule2_off_hours_all_accounts.sql` | **Rule 2 for all accounts.** |
| `queries/07_rule6_merchant_risk.sql` | Rule 6 with a stand-in for "alerted" (the alerts table is still empty). |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- `behaviour_baselines`: **597** rows. Account 1: average 5,980.49, 11 distinct hours, 3 cities.
- Rule 1: **145** transactions with z > 3 across the table; 12052 is the top (6.97). Most are ordinary: amounts are skewed.
- Rule 2: two hits, **12043** (the planted 02:30) and 12030 (a false alarm: one 3 p.m. transaction out of 52).
- Rule 4: exactly **12049, 12050, 12051**, with counts 6, 7, 8.
- Rule 6 stand-in: merchant **50** on top at 7.5× the platform rate; 5 merchants exceed 2×.

## Concepts you must be able to explain (viva)

- **WHERE vs HAVING.** Rows before grouping vs groups after. Only HAVING may hold an aggregate.
- **GROUP BY rule.** Every SELECT column is either grouped or aggregated (`ONLY_FULL_GROUP_BY`).
- **Logical order of a SELECT.** FROM/JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT.
- **Subquery kinds.** Scalar · IN · EXISTS · correlated (re-run per outer row) · derived table (in FROM).
- **NOT IN vs NOT EXISTS.** `NOT IN` returns nothing if the list contains NULL.
- **WITH ROLLUP.** Adds subtotal and grand-total rows.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout step 8 (advanced SQL: joins, subqueries, analytics).

## Results (captured from the running database)

### Evidence: Rule 4 (velocity) complete

Script: [`week-08-groupby-subqueries/queries/02_having.sql`](../../week-08-groupby-subqueries/queries/02_having.sql)

```text
+------------+-----------------+
| account_id | successful_txns |
+------------+-----------------+
|          1 |              52 |
|        154 |              30 |
|        543 |              30 |
+------------+-----------------+
+-------------+------+------------+
| merchant_id | txns | avg_amount |
+-------------+------+------------+
|          50 |  253 |    4378.00 |
+-------------+------+------------+
+------------+--------+---------------------+----------------+
| account_id | txn_id | txn_time            | txns_in_window |
+------------+--------+---------------------+----------------+
|          1 |  12049 | 2026-08-17 14:02:00 |              6 |
|          1 |  12050 | 2026-08-17 14:02:24 |              7 |
|          1 |  12051 | 2026-08-17 14:02:48 |              8 |
+------------+--------+---------------------+----------------+
```

### Evidence: Rule 1 for all accounts

Script: [`week-08-groupby-subqueries/queries/05_rule1_high_amount_all_accounts.sql`](../../week-08-groupby-subqueries/queries/05_rule1_high_amount_all_accounts.sql)

```text
+--------+------------+----------+----------+---------+
| txn_id | account_id | amount   | acct_avg | z_score |
+--------+------------+----------+----------+---------+
|  12052 |          1 | 95000.00 |  5980.49 |    6.97 |
|  12054 |         94 | 41462.45 |  3413.10 |    5.05 |
|  12063 |         46 | 30544.64 |  3131.96 |    4.92 |
|   1263 |        446 | 16317.70 |  2207.29 |    4.58 |
|   4828 |        392 | 14753.36 |  2053.00 |    4.37 |
|   5207 |        399 | 11092.76 |  1632.17 |    4.35 |
|  12059 |        285 | 69888.23 |  5483.09 |    4.33 |
|  12062 |        165 | 62629.96 |  5581.71 |    4.29 |
|   7323 |        405 |  8132.39 |  1323.77 |    4.27 |
|   3517 |        161 | 19012.34 |  2685.69 |    4.26 |
+--------+------------+----------+----------+---------+
```

### Evidence: Rule 6 stand-in

Script: [`week-08-groupby-subqueries/queries/07_rule6_merchant_risk.sql`](../../week-08-groupby-subqueries/queries/07_rule6_merchant_risk.sql)

```text
+-------------+---------------------------+------+---------+-------------------+-------------------+----------------+
| merchant_id | merchant_name             | txns | flagged | merchant_rate_pct | platform_rate_pct | times_platform |
+-------------+---------------------------+------+---------+-------------------+-------------------+----------------+
|          50 | Ramirez and Sons          |  253 |      15 |              5.93 |              0.79 |            7.5 |
|          21 | Chavez-Hall               |  255 |       6 |              2.35 |              0.79 |            3.0 |
|          35 | Anderson Group            |  236 |       5 |              2.12 |              0.79 |            2.7 |
|          11 | Acosta, Garcia and Moreno |  236 |       4 |              1.69 |              0.79 |            2.2 |
|          27 | Aguirre LLC               |  252 |       4 |              1.59 |              0.79 |            2.0 |
+-------------+---------------------------+------+---------+-------------------+-------------------+----------------+
```


---
