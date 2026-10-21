# Week 11 — Testing, documentation and the demo



**Lab:** Not a numbered lab. **Mini-project deliverables due 30 Oct 2026**: report (≤ 15 pages), slides (10-12), code + README + results, optional 2-3 min video.
**Theory lectures this lines up with:** all

Prove it works, write it up, rehearse it. No new SQL features.

## What was added

| File | What it is |
|---|---|
| `tests/test_sentinel.py` | 27 pytest tests: the five personas, the live trigger, constraints, `transfer_funds`, views, roles. Leaves the database as it found it. |
| `check.sql` | Whole-project invariants: 13 tables, 11 views, 5 routines, 3 triggers, 1 event, … |
| `docs/report_outline.md` | The 15-page report mapped to the handout's 13 steps, with file pointers and a screenshot checklist. |
| `docs/slides_outline.md · demo_script.md` | A 12-slide outline and a timed 5-minute demo script. |
| `docs/viva_questions.md` | 48 questions with two-sentence answers about *this* project. |
| `docs/limitations.md · performance.md` | Measured weaknesses and numbers: say them before the examiner does. |
| `../docs/LAB_EXAM_CHEATSHEET.md` | MySQL syntax for experiments 1-9, with the Oracle-isms that fail. |

Files in `sql/` are **loaded by the build** (`scripts/build.sh`). Files in `queries/`, `demo/` and `lab-practice/` are run by hand and are checked by `scripts/check.sh`.


## What you should see

- `scripts/check.sh 11`: **98 assertions** plus every query/demo script running clean.
- `pytest`: **27 passed**, and a before/after row count that proves the tests left nothing behind.

## Concepts you must be able to explain (viva)

- **Test layers.** SQL assertions per week (`check.sql`) · whole-project invariants · behavioural tests through a real client (pytest).
- **Self-cleaning tests.** Writes happen inside a transaction that is rolled back; `transfer_funds` commits by design, so its test restores the balances.
- **Be honest.** `limitations.md` is part of the deliverable. An examiner trusts a student who names their own weaknesses.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../../docs/LAB_EXAM_CHEATSHEET.md).


## Handout step covered

Handout steps 11-13 (testing, documentation, presentation).

## Results (captured from the running database)

### Evidence: Whole-project invariants

Script: [`week-11-final-polish/check.sql`](../../week-11-final-polish/check.sql)

```text
+-----------+-------------------------------------------------------------------------------------------------------------------------------------+
| 13 tables | IF((SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='sentinel' AND table_type='BASE TABLE') = 13, 'PASS', 'FAIL') |
+-----------+-------------------------------------------------------------------------------------------------------------------------------------+
| 13 tables | PASS                                                                                                                                |
+-----------+-------------------------------------------------------------------------------------------------------------------------------------+
+----------+---------------------------------------------------------------------------------------------------------+
| 11 views | IF((SELECT COUNT(*) FROM information_schema.views  WHERE table_schema='sentinel') = 11, 'PASS', 'FAIL') |
+----------+---------------------------------------------------------------------------------------------------------+
| 11 views | PASS                                                                                                    |
+----------+---------------------------------------------------------------------------------------------------------+
+----------------------------------------------+------------------------------------------------------------------------------------------------------------+
| 5 stored routines (1 function, 4 procedures) | IF((SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='sentinel') = 5, 'PASS', 'FAIL') |
+----------------------------------------------+------------------------------------------------------------------------------------------------------------+
| 5 stored routines (1 function, 4 procedures) | PASS                                                                                                       |
+----------------------------------------------+------------------------------------------------------------------------------------------------------------+
+------------+------------------------------------------------------------------------------------------------------------+
| 3 triggers | IF((SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema='sentinel') = 3, 'PASS', 'FAIL') |
+------------+------------------------------------------------------------------------------------------------------------+
| 3 triggers | PASS                                                                                                       |
+------------+------------------------------------------------------------------------------------------------------------+
+---------+----------------------------------------------------------------------------------------------------------+
| 1 event | IF((SELECT COUNT(*) FROM information_schema.events   WHERE event_schema='sentinel') = 1, 'PASS', 'FAIL') |
+---------+----------------------------------------------------------------------------------------------------------+
| 1 event | PASS                                                                                                     |
+---------+----------------------------------------------------------------------------------------------------------+
+--------------------+------------------------------------------------------------+
| 8 rule_config rows | IF((SELECT COUNT(*) FROM rule_config) = 8, 'PASS', 'FAIL') |
+--------------------+------------------------------------------------------------+
| 8 rule_config rows | PASS                                                       |
+--------------------+------------------------------------------------------------+
... (12 more lines)
```


---
