# Week 5 — Functions: number, aggregate, string, date



**Lab:** Handout lab list **#5 — Functions** (NUMBER, AGGREGATE, CHARACTER, DATE)  ·  lab manual "Implementation of different types of function"
**Theory lectures this lines up with:** 12–17 (functions)

Use every function family on real data, and use them to build the first three pieces of fraud logic by hand: the z-score (Rule 1), the hour of day (Rule 2) and the distance and speed between cities (Rule 5).

## What was added

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

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout step 8 (advanced SQL: joins and subqueries ahead; functions underpin all rules).

## Results (captured from the running database)

### Evidence: Rule 1 by hand: the 95,000 payment

Script: [`week-05-functions/queries/05_rule1_high_amount.sql`](../../week-05-functions/queries/05_rule1_high_amount.sql)

```text
+------------------+-----------------+
| account1_average | account1_stddev |
+------------------+-----------------+
|          5980.49 |        12765.36 |
+------------------+-----------------+
+--------+----------+---------+-------------------+
| txn_id | amount   | z_score | reason            |
+--------+----------+---------+-------------------+
|  12052 | 95000.00 |    6.97 | High amount (z=7) |
+--------+----------+---------+-------------------+
```

### Evidence: Rule 5 by hand: Delhi to Chennai in 10 minutes

Script: [`week-05-functions/queries/07_rule5_impossible_travel_by_hand.sql`](../../week-05-functions/queries/07_rule5_impossible_travel_by_hand.sql)

```text
+-------------+---------+-------------------+-------------------+
| distance_km | minutes | implied_speed_kmh | verdict           |
+-------------+---------+-------------------+-------------------+
|      1767.7 |      10 |             10606 | IMPOSSIBLE TRAVEL |
+-------------+---------+-------------------+-------------------+
```


---
