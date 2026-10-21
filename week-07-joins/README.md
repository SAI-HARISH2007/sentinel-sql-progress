# Week 7 — Joins: inner, outer, natural, self

[← Week 6](../week-06-operators/README.md) · [Project README](../README.md) · [Week 8 →](../week-08-groupby-subqueries/README.md)

**Lab:** Handout lab list **#7 — Joins** (INNER, OUTER, NATURAL, SELF)  ·  lab manual "Implementation of different types of Joins"
**Theory lectures this lines up with:** 18–20 (joins)

Combine tables. Joins give the first *real* rules: **Rule 3** (new device) with an anti-join, the first half of **Rule 4** (velocity) with a self-join, and **Rule 5** for every account at once.

## What you add this week

| File | What it is |
|---|---|
| `queries/01_inner_join.sql` | Seven-table join telling the whole story of the ₹95,000 payment; CROSS JOIN. |
| `queries/02_outer_joins.sql` | LEFT, RIGHT, anti-join (`… IS NULL`), and a FULL OUTER emulation with UNION. |
| `queries/03_natural_join.sql` | NATURAL JOIN, its pitfall, and `USING`. |
| `queries/04_self_join.sql` | Same-first-name users; the velocity pairs for the burst persona. |
| `queries/05_rule3_new_device.sql` | **Rule 3**: transactions on a device the account never used. |
| `queries/06_rule5_impossible_travel_pairs.sql` | **Rule 5 for all accounts** via a self-join. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.

## Run it

```bash
scripts/build.sh 7 && scripts/check.sh 7
```

(Without Docker: set `DB_HOST=127.0.0.1` and use your own MySQL 8; see the project README.)

## What you should see

- Txn 12052 → Tammy Allison, merchant Cline-Ayala, Mumbai, Android 14.
- **434** accounts have never logged in (anti-join). Every device appears in a transaction (0 unused).
- `merchants NATURAL JOIN locations` returns **0** rows: three shared column names must all match.
- The burst persona yields **28** pairs inside 5 minutes (8 transactions → C(8,2)).
- Rule 3 flags **16** transactions: 12052 plus the bad-merchant rows. Rule 5 gives **33** pairs; only the first (account 1, Delhi → Chennai) is the planted one. **32 are noise**, because the seed gives every transaction a random city (`limitations.md` #1).

## Concepts you must be able to explain (viva)

- **Inner vs outer.** Inner keeps only matching pairs. LEFT keeps all left rows (NULLs on the right). RIGHT mirrors it.
- **Anti-join.** `LEFT JOIN … WHERE right.key IS NULL`: "rows with no match".
- **Self join.** The same table twice under two aliases; use `<` or `>` on ids so each pair appears once.
- **Natural join.** Joins on all same-named columns. Fragile; prefer `ON` or `USING`.
- **Join vs subquery.** Same questions can be asked either way; joins read well for combining, subqueries for filtering.
- **Cross join.** Every combination. Forgetting the `ON` clause creates one by accident.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../docs/LAB_EXAM_CHEATSHEET.md).

## Try it yourself

1. Which merchants have **no** transactions at all? (They don't exist here: explain why the result is empty.)
2. Rewrite Rule 3 with `NOT EXISTS` instead of `LEFT JOIN … IS NULL`. Do both give 16?
3. Add the user's name to query 06's output (two more joins).

## Watch out

- A join on a non-unique column multiplies rows. Always sanity-check counts.
- In query 06, `HAVING` is used only so the aliases `distance_km` and `minutes` can be filtered; Week 8 explains HAVING properly.

## Where this goes in the final report

Handout step 8 (advanced SQL: joins).

## Push checklist

Exact commands for this week are in [`GIT_COMMANDS.md`](../GIT_COMMANDS.md) (section "Week 7"). Commit message: `Week 7: joins — inner/outer/natural/self, Rule 3 (new device), Rule 5 pairs`.
Tick Week 7 in [`PROGRESS.md`](../PROGRESS.md) with the **real** date.

> **If your lab teaches this topic in a different order,** keep the folder but change when you push it. Each week's SQL depends only on earlier weeks (Weeks 2→3 and 4→5+ are the only hard dependencies).
