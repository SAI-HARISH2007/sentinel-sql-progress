# Week 7 — Joins: inner, outer, natural, self



**Lab:** Handout lab list **#7 — Joins** (INNER, OUTER, NATURAL, SELF)  ·  lab manual "Implementation of different types of Joins"
**Theory lectures this lines up with:** 18–20 (joins)

Combine tables. Joins give the first *real* rules: **Rule 3** (new device) with an anti-join, the first half of **Rule 4** (velocity) with a self-join, and **Rule 5** for every account at once.

## What was added

| File | What it is |
|---|---|
| `queries/01_inner_join.sql` | Seven-table join telling the whole story of the ₹95,000 payment; CROSS JOIN. |
| `queries/02_outer_joins.sql` | LEFT, RIGHT, anti-join (`… IS NULL`), and a FULL OUTER emulation with UNION. |
| `queries/03_natural_join.sql` | NATURAL JOIN, its pitfall, and `USING`. |
| `queries/04_self_join.sql` | Same-first-name users; the velocity pairs for the burst persona. |
| `queries/05_rule3_new_device.sql` | **Rule 3**: transactions on a device the account never used. |
| `queries/06_rule5_impossible_travel_pairs.sql` | **Rule 5 for all accounts** via a self-join. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


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

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout step 8 (advanced SQL: joins).

## Results (captured from the running database)

### Evidence: Seven-table join: the whole story of one payment

Script: [`week-07-joins/queries/01_inner_join.sql`](../../week-07-joins/queries/01_inner_join.sql)

```text
+--------+---------------+------------+----------+---------------+---------------+----------+-------------+------------+---------------------+
| txn_id | full_name     | account_id | amount   | merchant_name | category_name | txn_city | device_type | os         | txn_time            |
+--------+---------------+------------+----------+---------------+---------------+----------+-------------+------------+---------------------+
|  12052 | Tammy Allison |          1 | 95000.00 | Cline-Ayala   | Fashion       | Mumbai   | mobile      | Android 14 | 2026-08-18 11:00:00 |
+--------+---------------+------------+----------+---------------+---------------+----------+-------------+------------+---------------------+
+--------+---------------+
| txn_id | merchant_name |
+--------+---------------+
|  12052 | Cline-Ayala   |
+--------+---------------+
+---------------------+
| merchants_with_txns |
... (21 more lines)
```

### Evidence: Rule 3: new device

Script: [`week-07-joins/queries/05_rule3_new_device.sql`](../../week-07-joins/queries/05_rule3_new_device.sql)

```text
+--------+------------+-----------+------------------------------------------------------------------+----------+
| txn_id | account_id | device_id | fingerprint_hash                                                 | amount   |
+--------+------------+-----------+------------------------------------------------------------------+----------+
|  12052 |          1 |       999 | NEVER_SEEN_DEVICE_HASH_001                                       | 95000.00 |
|  12053 |        117 |       109 | d95e5209182f0cd4a959c0a71879d0ac7a281c48cd8f1a8b135990a337d64a29 | 66536.48 |
|  12054 |         94 |        82 | 225093b22ba889759761bf9d97bcf7181d20034f4606c086e0383fe9592bd0aa | 41462.45 |
|  12055 |        145 |        19 | e5c3a3eab2dfaa06909c048da252ff9c315b6946a2ab2418bd99c755caeefa94 |  5694.10 |
|  12056 |         77 |        33 | 57aa346d77a61b6a6806beb4e865763f29f8cda2ca2dacfd85d66b217743fcfe | 10559.60 |
|  12057 |        113 |       179 | 00c6a81aef67048beb91e87a3e05d963fd8d8164fb4dcef10564db8417d4ab43 | 43111.67 |
|  12058 |        316 |       165 | 1bf19464968316be77526f96d1d2587088d7fd9e45dea34d12fe8bfc88f80a8c | 60943.44 |
|  12059 |        285 |       104 | 0dfbc86ad6de9296cf92b2c6aec37c777fa94bd1002d5fe2e69ca6ec98b556a3 | 69888.23 |
|  12060 |        451 |       121 | a8690afc851337687f2cf531d35c0da9202f8ba81034fed581ca14e11a110310 | 51180.91 |
|  12061 |        158 |        21 | 24bc87b2b67c30778248ee27be5da0ac0900b605a5704ef06b50bc4c18c4af54 | 61521.54 |
|  12062 |        165 |       127 | 4ac7acc4bedf04dc077aa1267109fbdf8e8547f2a6dd9ecd00baa60c6e98969d | 62629.96 |
|  12063 |         46 |       106 | 4b209ba5b3f5e1e8086576111237a121380aa359ff8a868640bfe5b907ee1070 | 30544.64 |
|  12064 |        260 |       170 | 0fce1eecf97cd45f808ffce56ebe5bf74bb9bf97c31e52adc96d395b5a3af85e | 24191.73 |
|  12065 |        358 |        54 | 51218c513959ae5f3b8a0b18bb6f8f95f3e7e100be943ecb6add03f87ca65353 | 34249.12 |
|  12066 |        495 |       131 | 8cd4347f9935f6687e9aca3a8d373db3f946bd9dd35e6245f2a867dea8b2c8df | 10552.67 |
|  12067 |         20 |        90 | de5c6044071daeda338e6c198d13bc628ba51594662de7839d660d1e21c0eb0a | 59733.72 |
+--------+------------+-----------+------------------------------------------------------------------+----------+
+-------------------------+
| txns_on_unknown_devices |
+-------------------------+
|                      16 |
+-------------------------+
```


---
