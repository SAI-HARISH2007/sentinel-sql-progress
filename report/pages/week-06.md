# Week 6 — Operators: arithmetic, comparison, logical, special, set



**Lab:** Handout lab list **#6 — Operators** (ARITHMETIC, LOGICAL, COMPARISON, SPECIAL, SET)  ·  lab manual "Implementation of different types of operators"
**Theory lectures this lines up with:** 12–17 (operators)

Every operator family on real data, ending in a deliberately naive "first-cut fraud screen" built from fixed thresholds, which shows *why* the later weeks compare each account with its own history.

## What was added

| File | What it is |
|---|---|
| `queries/01_arithmetic_operators.sql` | `+ - * / DIV %`, precedence, division by zero. |
| `queries/02_comparison_operators.sql` | `= <> < > <= >= <=>`; the `= NULL` trap. |
| `queries/03_logical_operators.sql` | AND, OR, NOT, XOR and why brackets matter (1,300 rows vs 148). |
| `queries/04_special_operators.sql` | BETWEEN, IN, NOT IN, LIKE (`%` and `_`), IS NULL, REGEXP. |
| `queries/05_set_operators.sql` | UNION, UNION ALL, INTERSECT, EXCEPT on lists of accounts. |
| `queries/06_first_cut_fraud_screen.sql` | A screen from fixed rules of thumb: **216 transactions caught, only 27 planted**. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- `amount > 5000 AND (status='failed' OR status='pending')` → **148** rows; the same without brackets → **1,300**.
- Accounts with a payment over 50,000: 8. Of those, **only account 20** also made a large night payment (INTERSECT); the other **7** are EXCEPT.
- The first-cut screen returns **216** rows. Most are innocent: the cost of fixed thresholds.

## Concepts you must be able to explain (viva)

- **Precedence.** `NOT` > `AND` > `OR`; `*` `/` before `+` `-`. Brackets remove doubt.
- **NULL logic.** Any comparison with NULL is *unknown*. Use `IS NULL` or `<=>`.
- **BETWEEN.** Inclusive at both ends.
- **LIKE.** `%` = any run of characters, `_` = exactly one.
- **Set operators.** Same number of columns, compatible types. UNION removes duplicates; UNION ALL keeps them. `EXCEPT` = Oracle's `MINUS` (MySQL 8.0.31+).
- **False positives.** Fixed thresholds treat a rich customer's normal payment as fraud. Rule 1 fixes that with a per-account baseline.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout step 8 (advanced SQL).

## Results (captured from the running database)

### Evidence: Set operators

Script: [`week-06-operators/queries/05_set_operators.sql`](../../week-06-operators/queries/05_set_operators.sql)

```text
+------------+
| account_id |
+------------+
|          1 |
|         20 |
|        117 |
|        158 |
|        165 |
+------------+
+--------+
| a_or_b |
+--------+
|     31 |
+--------+
+----------------+
| rows_union_all |
+----------------+
|             32 |
+----------------+
+------------+
| account_id |
+------------+
|         20 |
+------------+
+-------------------+
| big_but_not_night |
+-------------------+
|                 7 |
+-------------------+
+-----------------+--------+------------+
| flagged_because | txn_id | account_id |
+-----------------+--------+------------+
| small hours     |  12043 |          1 |
| big amount      |  12052 |          1 |
+-----------------+--------+------------+
```

### Evidence: First-cut fraud screen

Script: [`week-06-operators/queries/06_first_cut_fraud_screen.sql`](../../week-06-operators/queries/06_first_cut_fraud_screen.sql)

```text
+--------+------------+----------+------+---------+--------------------------------------------+
| txn_id | account_id | amount   | hr   | status  | why                                        |
+--------+------------+----------+------+---------+--------------------------------------------+
|  12052 |          1 | 95000.00 |   11 | success | very large amount, device 999 (never seen) |
|  12059 |        285 | 69888.23 |   18 | success | very large amount                          |
|  12053 |        117 | 66536.48 |   12 | success | very large amount                          |
|  12062 |        165 | 62629.96 |   21 | success | very large amount                          |
|  12061 |        158 | 61521.54 |   20 | success | very large amount                          |
|  12058 |        316 | 60943.44 |   17 | success | very large amount                          |
|  12067 |         20 | 59733.72 |    2 | success | very large amount, large night payment     |
|  12060 |        451 | 51180.91 |   19 | success | very large amount                          |
|  12065 |        358 | 34249.12 |    0 | success | large night payment                        |
|   2821 |         86 | 21238.33 |    4 | success | large night payment                        |
|   1337 |        302 | 15021.19 |    1 | success | large night payment                        |
|   5696 |        481 | 13373.93 |    4 | success | large night payment                        |
|    415 |        283 | 12474.93 |    0 | failed  | large night payment                        |
|   8207 |          7 | 12231.30 |    0 | success | large night payment                        |
|   2516 |        257 | 12205.23 |    4 | success | large night payment                        |
+--------+------------+----------+------+---------+--------------------------------------------+
+-------------+
| screened_in |
+-------------+
|         216 |
+-------------+
```


---
