# Product Requirements Document — Sentinel

| | |
|---|---|
| **Product** | Sentinel — In-Database Real-Time Fraud Detection System |
| **Course** | CS/AI/AIM/DS 202 Database Management Systems, Sem III, A.Y. 2026-27, ICFAI Faculty of Science & Technology |
| **Team** | Sai Haresh Anand S · Seshivardhini |
| **Version / date** | 1.0 · 20 Oct 2026 |
| **Status** | Weeks 1-11 implemented in the repo; lab-by-lab dates in `PROGRESS.md` are still blank (fill only when actually done) |
| **Deadline** | Mini-project demo/submission 30 Oct 2026 · lab exam 26-30 Oct 2026 |

Detail lives elsewhere; this page links, not copies: [problem statement](../week-01-intro-er-design/docs/problem-statement.md) · [limitations](../week-11-final-polish/docs/limitations.md) · [performance](../week-11-final-polish/docs/performance.md) · [viva Q&A](../week-11-final-polish/docs/viva_questions.md).

## 1. Problem
Fraud checks usually run in application code around the database. Thresholds are hard-coded (a change needs a deploy), the fraudulent row is already committed before it is checked, and a separate fraud system needs its own data copy and pipeline.

**Core question:** can the database itself flag a suspicious transaction the moment it is inserted, using only SQL features taught in this course, and say *why*?

## 2. Goals
1. Clean relational schema (users, accounts, merchants, devices, locations, transactions, alerts, config) in 3NF, with integrity enforced by the database.
2. Six fraud rules written as plain SQL, then packaged progressively: query → view → stored procedure.
3. Automatic scoring via a trigger on `INSERT INTO transactions`.
4. All thresholds in `rule_config`, so tuning is an `UPDATE`.
5. Demonstrate transactions (COMMIT/ROLLBACK, locking) and least-privilege roles.
6. Repo mirrors the lab syllabus: each `week-NN-*` folder adds one layer and depends only on earlier weeks.

## 3. Non-goals
Real payment gateway, machine learning, UI/login, cloud deployment, production-grade security.

## 4. Users
| User | Need |
|---|---|
| Fraud analyst (role) | Read alerts and their reasons; no access to raw data changes |
| Application / payment writer (role) | Insert transactions; call `transfer_funds` |
| DBA / admin | Tune thresholds, refresh baselines, back-fill history |
| Evaluators (faculty) | See each lab topic applied; defend design in viva |

## 5. Functional requirements
| ID | Requirement | Acceptance criterion | Week |
|---|---|---|---|
| FR-1 | Store users, accounts, merchants, devices, locations, transactions | 13 tables; ~12,067 seeded transactions incl. 5 fraud personas (ids 12041-12067) | 2-4 |
| FR-2 | Six rules, each with a human-readable reason | Rule 1 z-score amount · 2 off-hours · 3 new device · 4 velocity · 5 impossible travel · 6 merchant risk; each has a view | 5-9 |
| FR-3 | Per-account behaviour baseline | `behaviour_baselines` refreshed by a scheduled event | 8, 10 |
| FR-4 | Auto-score new transactions | `trg_after_txn_insert` → `score_transaction(txn_id)`; score > 0 writes `alerts` row with JSON `reasons` | 10 |
| FR-5 | Thresholds configurable | All rule parameters read from `rule_config` | 4 |
| FR-6 | Analyst isolation | Analyst role can SELECT alerts, cannot modify transactions | 9 |
| FR-7 | Atomic transfer | `transfer_funds` is all-or-nothing | 10 |
| FR-8 | Back-fill | `backfill_alerts(from, to)` scores historical rows | 10 |

## 6. Non-functional requirements
| Area | Requirement | Current evidence |
|---|---|---|
| Repeatability | Every SQL file re-runnable (`DROP … IF EXISTS`); `make all` builds weeks 1-10 | Ends `failed: 0` (98 assertions) |
| Correctness | Automated tests | 27 pytest tests; per-week `check.sql` all PASS |
| Performance | Interactive on 12k+ rows | Date-range report cost 1349 → 174 with index; scoring ≈ 2 ms/insert (≈ 500 txn/s) |
| Portability | MySQL 8.0.31+ (Docker 8.4 image provided) | Not portable to Oracle (JSON, ENUM, INTERSECT) |
| Cost | ₹0 | MySQL + Docker; Python only for data/report scripts |
| Integrity of claims | No invented numbers | Benchmarks measured; see `CHANGES_FROM_ORIGINAL.md` |

## 7. Success metrics
- `make all` ends `failed: 0`; `make test` 27/27 green.
- Each of the 5 personas triggers its intended rule(s) in the 90-second demo (`week-10-procedures-triggers/demo/01_fraud_demo.sql`).
- Schema matches frozen fingerprint (`scripts/compare_to_reference.sh`).
- Both team members can explain any week's "Concepts" section aloud in the viva.

## 8. Milestones
| Date | Milestone |
|---|---|
| Done in repo | Weeks 1-11 content, report PDF, slides/demo/viva material |
| Before 26 Oct | Re-run `make all` on your own machine; fill `PROGRESS.md` honestly |
| 26-30 Oct | Lab exam (experiments 1-9, closed book) — use `docs/LAB_EXAM_CHEATSHEET.md` |
| 30 Oct | Mini-project demo + submission |
| 16 Nov onward | Comprehensive exam — DBMS theory reuses this project's examples |

## 9. Risks and known limitations
| Risk | Mitigation |
|---|---|
| Synthetic data gives ~32 background "impossible travel" hits | Documented (limitations #1); one hit is the planted traveller |
| Z-score on skewed amounts flags 1.2 % | Documented; fix would be median + MAD |
| Rule 6 feeds on other rules' alerts | Guard `merchant_risk_min_alerts = 3` |
| Statistics include the transaction being scored | Documented; baselines table is the proper fix |
| Trigger makes inserts ~50× slower | Accepted trade-off; load bulk data before installing trigger |
| Viva depth: built with assistant help, must be defended personally | Explain from week READMEs and `viva_questions.md` |
| Git history is visible to faculty | Never fake commit dates (`GIT_COMMANDS.md`) |

## 10. Open questions
- Does the instructor teach DDL → constraints → DML (handout) or DDL → DML → constraints (lab manual)? Both work; confirm.
- Should the hand-drawn ER diagram follow a specific notation the faculty uses? (Generated diagram is reference only.)
- Is a live demo or a recorded one expected on 30 Oct?

## 11. Future work (out of scope now)
Per-account home location in the data generator; robust (median/MAD) amount rule; merchant risk from confirmed fraud only; `txn_type` for transfers; secrets from environment.
