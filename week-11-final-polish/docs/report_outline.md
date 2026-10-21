# Final report outline (max 15 pages) — mapped to the handout's 13 steps

The handout's "Project Structure" has 13 steps and asks for: a report (max 15 pages), a slide deck (10–12 slides), code + README + results, and an optional 2–3 minute demo video.
For each step: what to write, which file already contains it, and which screenshot to take. Page budget in brackets.

| # | Handout step | What to write | Source in this repo | Screenshot |
|---|---|---|---|---|
| — | Cover page + abstract [1] | Title, names, course code AI202, one paragraph: "fraud detection inside MySQL" | `week-01.../docs/problem-statement.md` §1–2 | — |
| 1–3 | Title, problem, objectives [1] | Copy and shorten | `problem-statement.md` §2–3 | — |
| 4 | Requirements [1] | FR/NFR table | `problem-statement.md` §4 | — |
| 5 | ER model [2] | The diagram, entities, cardinalities, and the ER→relational rules | `week-01.../docs/er-diagram.md`, `er-to-relational.md`. **Draw the diagram yourselves in your faculty's notation** (rectangles/ellipses/diamonds). | The ER diagram |
| 6 | Schema + normalisation [2] | Table list, keys, the 3NF argument for 3 representative tables (`users`, `account_devices`, `transactions`) | `week-03.../docs/normalization.md` | `SHOW CREATE TABLE transactions` |
| 7 | SQL: DDL, DML, DCL [2] | One representative snippet for each; the constraint tour | `week-02.../sql/`, `week-03.../sql/01_constraints.sql`, `week-04.../demo/dml_tour.sql`, `week-09.../sql/40_roles_dcl.sql` | `constraint_violations.sql` output (the errors!); `dcl_demo.sh` output |
| 8 | Advanced SQL [3] | Rules as queries → views → procedure → trigger. Show Rule 4 (velocity) at all four stages as the worked example | `week-07.../queries/04_self_join.sql`, `week-08.../queries/02_having.sql`, `week-09.../sql/10_rule_views.sql`, `week-10.../sql/20_score_transaction.sql` | `SELECT * FROM v_transaction_risk` ; `CALL score_transaction` result |
| 9 | Transactions [1] | ACID in `transfer_funds`; ordered locking; the concurrency demo | `week-10.../sql/50_transfer_funds.sql`, `demo/02`, `03`, `04` | transfer success + the four refusals; concurrency demo timing |
| 10 | Indexing [1] | Which indexes and why; measured before/after; be honest that the gain is small at this size | `week-09.../docs/benchmark_measured.md`, `docs/performance.md` | the two `EXPLAIN ANALYZE` plans side by side |
| 11 | Testing [1] | `scripts/check.sh 11` (98 assertions), pytest (27 tests), the five personas, the false-alarm test | `week-*/check.sql`, `week-11.../tests/` | `make all` output; `pytest -v` output |
| 12 | Documentation | This repository itself | `README.md`, `AGENTS.md` | — |
| 13 | Conclusion + reflection [1] | What worked; what you would change (use `limitations.md`) | `week-11.../docs/limitations.md` | — |

**Screenshot checklist (take them once everything is built):** ER diagram · `SHOW TABLES` · constraint violation errors · `v_transaction_risk` top rows · the 90-second demo (alert appears) · audit_log row with `analyst_user@localhost` · `EXPLAIN ANALYZE` before/after · `make all` all-green · `pytest` 27 passed.

**Mark allocation** (from the original repo's PRD, which transcribed the handout): problem understanding 15 % · database design 15 % · SQL implementation 25 % · output accuracy 20 % · report + viva 25 %. The viva is a quarter of the marks: both team members must be able to explain every line. Read `viva_questions.md` aloud.
