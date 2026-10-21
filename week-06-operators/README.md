# Week 6 — Operators: arithmetic, comparison, logical, special, set

[← Week 5](../week-05-functions/README.md) · [Project README](../README.md) · [Week 7 →](../week-07-joins/README.md)

**Lab:** Handout lab list **#6 — Operators** (ARITHMETIC, LOGICAL, COMPARISON, SPECIAL, SET)  ·  lab manual "Implementation of different types of operators"
**Theory lectures this lines up with:** 12–17 (operators)

Every operator family on real data, ending in a deliberately naive "first-cut fraud screen" built from fixed thresholds, which shows *why* the later weeks compare each account with its own history.

## What you add this week

| File | What it is |
|---|---|
| `queries/01_arithmetic_operators.sql` | `+ - * / DIV %`, precedence, division by zero. |
| `queries/02_comparison_operators.sql` | `= <> < > <= >= <=>`; the `= NULL` trap. |
| `queries/03_logical_operators.sql` | AND, OR, NOT, XOR and why brackets matter (1,300 rows vs 148). |
| `queries/04_special_operators.sql` | BETWEEN, IN, NOT IN, LIKE (`%` and `_`), IS NULL, REGEXP. |
| `queries/05_set_operators.sql` | UNION, UNION ALL, INTERSECT, EXCEPT on lists of accounts. |
| `queries/06_first_cut_fraud_screen.sql` | A screen from fixed rules of thumb: **216 transactions caught, only 27 planted**. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.

## Run it

```bash
scripts/build.sh 6 && scripts/check.sh 6
```

(Without Docker: set `DB_HOST=127.0.0.1` and use your own MySQL 8; see the project README.)

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

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../docs/LAB_EXAM_CHEATSHEET.md).

## Try it yourself

1. Write the `NOT BETWEEN` version of query 04's first statement.
2. Which accounts are in A but not B if A = payments > 50,000 and B = payments made at hour 2? Use EXCEPT.
3. Why does `SELECT 'a' || 'b'` return 0 in MySQL? (cheat sheet)

## Watch out

- `INTERSECT` / `EXCEPT` need MySQL 8.0.31+. On older lab PCs use `IN` / `NOT IN` or `EXISTS`.
- `UNION` sorts to de-duplicate: prefer `UNION ALL` when duplicates are impossible or harmless.

## Where this goes in the final report

Handout step 8 (advanced SQL).

## Push checklist

Exact commands for this week are in [`GIT_COMMANDS.md`](../GIT_COMMANDS.md) (section "Week 6"). Commit message: `Week 6: operators — arithmetic/comparison/logical/special/set, first-cut fraud screen`.
Tick Week 6 in [`PROGRESS.md`](../PROGRESS.md) with the **real** date.

> **If your lab teaches this topic in a different order,** keep the folder but change when you push it. Each week's SQL depends only on earlier weeks (Weeks 2→3 and 4→5+ are the only hard dependencies).
