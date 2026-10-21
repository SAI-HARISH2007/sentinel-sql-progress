# Week 8 — GROUP BY, HAVING, ORDER BY — and subqueries

[← Week 7](../week-07-joins/README.md) · [Project README](../README.md) · [Week 9 →](../week-09-views-indexes-dcl/README.md)

**Lab:** Handout lab list **#8 — GROUP BY, HAVING, ORDER BY**  ·  lab manual Exp 7 (and Exp 9 "Subqueries")
**Theory lectures this lines up with:** 18–20 (group by, having, order by, subqueries)

Aggregate per group and filter groups. The three "statistical" rules are now complete for **every** account at once: Rule 1, Rule 2, Rule 4 (velocity). A stand-in for Rule 6 appears, and the first *permanent* data computed by SQL fills `behaviour_baselines`.

## What you add this week

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

## Run it

```bash
scripts/build.sh 8 && scripts/check.sh 8
```

(Without Docker: set `DB_HOST=127.0.0.1` and use your own MySQL 8; see the project README.)

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

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../docs/LAB_EXAM_CHEATSHEET.md).

## Try it yourself

1. Write "accounts whose average is above the global average" two ways: scalar subquery and derived table.
2. Which month had the highest total? The lowest transaction count?
3. Explain in one sentence why Rule 2 can only fire for accounts with more than 50 transactions.

## Watch out

- `ORDER BY` inside a subquery is ignored unless paired with LIMIT.
- Rule 6's stand-in uses "payment over 10,000" as a pretend alert. The real rule arrives as a view in Week 9 and starts returning rows in Week 10.

## Where this goes in the final report

Handout step 8 (advanced SQL: joins, subqueries, analytics).

## Push checklist

Exact commands for this week are in [`GIT_COMMANDS.md`](../GIT_COMMANDS.md) (section "Week 8"). Commit message: `Week 8: GROUP BY/HAVING/ORDER BY + subqueries — Rules 1, 2, 4 complete; behaviour_baselines`.
Tick Week 8 in [`PROGRESS.md`](../PROGRESS.md) with the **real** date.

> **If your lab teaches this topic in a different order,** keep the folder but change when you push it. Each week's SQL depends only on earlier weeks (Weeks 2→3 and 4→5+ are the only hard dependencies).
