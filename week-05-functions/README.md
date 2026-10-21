# Week 5 — Functions: number, aggregate, string, date

[← Week 4](../week-04-dml/README.md) · [Project README](../README.md) · [Week 6 →](../week-06-operators/README.md)

**Lab:** Handout lab list **#5 — Functions** (NUMBER, AGGREGATE, CHARACTER, DATE)  ·  lab manual "Implementation of different types of function"
**Theory lectures this lines up with:** 12–17 (functions)

Use every function family on real data, and use them to build the first three pieces of fraud logic by hand: the z-score (Rule 1), the hour of day (Rule 2) and the distance and speed between cities (Rule 5).

## What you add this week

| File | What it is |
|---|---|
| `queries/01_number_functions.sql` | ROUND, CEIL, FLOOR, TRUNCATE, MOD, ABS, SQRT, POWER, GREATEST/LEAST, and the Haversine formula from sines and cosines. |
| `queries/02_aggregate_functions.sql` | COUNT, SUM, AVG, MIN, MAX, STDDEV_SAMP, VARIANCE; `COUNT(*)` vs `COUNT(col)`. |
| `queries/03_string_functions.sql` | UPPER, CONCAT, LEFT/RIGHT, SUBSTRING, INSTR, REPLACE, LPAD, TRIM; masking emails and phones. |
| `queries/04_date_functions.sql` | NOW, DATE, HOUR, DAYNAME, DATE_FORMAT, DATE_ADD, DATEDIFF, TIMESTAMPDIFF. |
| `queries/05_rule1_high_amount.sql` | **Rule 1 for one account**, with user variables. |
| `queries/06_rule2_off_hours_preview.sql` | Rule 2 preview using `HOUR()`. |
| `queries/07_rule5_impossible_travel_by_hand.sql` | **Rule 5 for the traveller persona.** |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.

## Run it

```bash
scripts/build.sh 5 && scripts/check.sh 5
docker exec -i sentinel-db mysql -uroot -psentinel_root_2026 -t sentinel < week-05-functions/queries/05_rule1_high_amount.sql
```

(Without Docker: set `DB_HOST=127.0.0.1` and use your own MySQL 8; see the project README.)

## What you should see

- Delhi → Chennai = **1767.7 km**. The traveller's 10-minute hop implies **10,606 km/h**, so `IMPOSSIBLE TRAVEL` (limit 900).
- Account 1: average **5,980.49**, standard deviation **12,765.36**. Txn 12052 (₹95,000) has **z = 6.97**.
- The only 00:00-04:59 transaction on account 1 is **12043**.

## Concepts you must be able to explain (viva)

- **Aggregate functions skip NULL.** …except `COUNT(*)`.
- **z-score.** `(x - mean) / standard deviation`: how many deviations from this account's normal. > 3 is unusual **if the data is bell-shaped**.
- **STDDEV_SAMP vs STDDEV_POP.** Sample (÷ n-1) when the rows are a sample of behaviour; population (÷ n) when they are everything. We use sample.
- **Haversine.** Great-circle distance on a sphere (radius 6371 km) from two latitude/longitude pairs.
- **User variables.** `SELECT … INTO @x` carries a value to the next statement. Session-scoped; Week 10 replaces them with `DECLARE`d variables.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../docs/LAB_EXAM_CHEATSHEET.md).

## Try it yourself

1. Write a query showing the masked version of every email in `users` (first 2 characters, then stars, then the domain).
2. How many hours between 12041 and 12042? Which date function gives it in seconds?
3. Change the speed limit in `rule_config` to 12,000 and re-run file 07. What does the verdict become? Change it back.

## Watch out

- `ROUND(x, -2)` rounds to hundreds (negative digits are legal).
- `TRUNCATE(x, 0)` is a *function*; `TRUNCATE TABLE` is DDL. Same word, different things.
- Rule 2's full version needs GROUP BY (Week 8); today it is only a preview.

## Where this goes in the final report

Handout step 8 (advanced SQL: joins and subqueries ahead; functions underpin all rules).

## Push checklist

Exact commands for this week are in [`GIT_COMMANDS.md`](../GIT_COMMANDS.md) (section "Week 5"). Commit message: `Week 5: functions — number/aggregate/string/date, Rule 1, Rule 2 preview, Rule 5 by hand`.
Tick Week 5 in [`PROGRESS.md`](../PROGRESS.md) with the **real** date.

> **If your lab teaches this topic in a different order,** keep the folder but change when you push it. Each week's SQL depends only on earlier weeks (Weeks 2→3 and 4→5+ are the only hard dependencies).
