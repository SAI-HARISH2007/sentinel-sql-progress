# Week 11 — Testing, documentation and the demo

[← Week 10](../week-10-procedures-triggers/README.md) · [Project README](../README.md)

**Lab:** Not a numbered lab. **Mini-project deliverables due 30 Oct 2026**: report (≤ 15 pages), slides (10-12), code + README + results, optional 2-3 min video.
**Theory lectures this lines up with:** all

Prove it works, write it up, rehearse it. No new SQL features.

## What you add this week

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

## Run it

```bash
make all                    # build weeks 1-10 and run all 98 assertions + demos
make test                   # pytest (installs mysql-connector-python)
scripts/compare_to_reference.sh   # schema still equals the frozen reference
```

(Without Docker: set `DB_HOST=127.0.0.1` and use your own MySQL 8; see the project README.)

## What you should see

- `scripts/check.sh 11`: **98 assertions** plus every query/demo script running clean.
- `pytest`: **27 passed**, and a before/after row count that proves the tests left nothing behind.

## Concepts you must be able to explain (viva)

- **Test layers.** SQL assertions per week (`check.sql`) · whole-project invariants · behavioural tests through a real client (pytest).
- **Self-cleaning tests.** Writes happen inside a transaction that is rolled back; `transfer_funds` commits by design, so its test restores the balances.
- **Be honest.** `limitations.md` is part of the deliverable. An examiner trusts a student who names their own weaknesses.

More questions with full answers: [`week-11-final-polish/docs/viva_questions.md`](../week-11-final-polish/docs/viva_questions.md). Syntax for the closed-book lab: [`docs/LAB_EXAM_CHEATSHEET.md`](../docs/LAB_EXAM_CHEATSHEET.md).

## Try it yourself

1. Time the 5-minute demo with a stopwatch, twice.
2. Take every screenshot on the checklist in `report_outline.md`.
3. Have a teammate ask you the questions in `viva_questions.md` in random order.

## Watch out

- Do not describe the false alarms (random cities, skewed z-scores) as bugs you fixed: they are properties of the synthetic data and of the method. Say so.

## Where this goes in the final report

Handout steps 11-13 (testing, documentation, presentation).

## Push checklist

Exact commands for this week are in [`GIT_COMMANDS.md`](../GIT_COMMANDS.md) (section "Week 11"). Commit message: `Week 11: tests, report/slides/demo material, limitations`.
Tick Week 11 in [`PROGRESS.md`](../PROGRESS.md) with the **real** date.

> **If your lab teaches this topic in a different order,** keep the folder but change when you push it. Each week's SQL depends only on earlier weeks (Weeks 2→3 and 4→5+ are the only hard dependencies).
