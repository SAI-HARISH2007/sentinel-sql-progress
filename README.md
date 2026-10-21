# Sentinel — in-database real-time fraud detection (week by week)

A banking-style MySQL database where **fraud detection lives inside the database**. Insert a transaction; a trigger scores it against six rules, each compared with that account's own history, and writes an alert that says *why*.

**Course:** CS/AI/AIM/DS 202 Database Management Systems, Semester III, A.Y. 2026-27, ICFAI Faculty of Science & Technology
**Team:** [Sai Haresh Anand S](https://github.com/SAI-HARISH2007) · Seshivardhini
**Report (PDF):** [`report/PROJECT_REPORT.pdf`](report/PROJECT_REPORT.pdf) — one section per week, with real query output. Per-week PDFs are in [`report/pdf/`](report/pdf/); Markdown versions sit next to them.

## How this repository is organised

The project is built **one lab at a time**. Each `week-NN-*` folder is one lab experiment and adds one layer; folders only depend on earlier ones.

| Week | Lab experiment | Adds | Report page |
|---|---|---|---|
| [1](week-01-intro-er-design/) | Intro to MySQL, ER design | Problem statement, ER diagram, ER→tables rules, `CREATE DATABASE` | [p.1](report/pages/week-01.md) |
| [2](week-02-ddl/) | DDL | 13 tables (columns only); ALTER / RENAME / DROP COLUMN | [p.2](report/pages/week-02.md) |
| [3](week-03-constraints/) | Constraints | PK, FK, UNIQUE, NOT NULL, DEFAULT, CHECK; 3NF argument | [p.3](report/pages/week-03.md) |
| [4](week-04-dml/) | DML | Rule thresholds + 12,067 transactions + 5 fraud personas | [p.4](report/pages/week-04.md) |
| [5](week-05-functions/) | Functions | Rule 1 (z-score), Rule 2 preview, Rule 5 by hand | [p.5](report/pages/week-05.md) |
| [6](week-06-operators/) | Operators | All operator families, first-cut fraud screen | [p.6](report/pages/week-06.md) |
| [7](week-07-joins/) | Joins | Rule 3 (new device), Rule 4 pairs, Rule 5 for all accounts | [p.7](report/pages/week-07.md) |
| [8](week-08-groupby-subqueries/) | GROUP BY / HAVING / ORDER BY, subqueries | Rules 1, 2, 4 for all accounts; baselines | [p.8](report/pages/week-08.md) |
| [9](week-09-views-indexes-dcl/) | Views, indexes (+ DCL) | Six rule views, combined risk view, measured indexes, roles | [p.9](report/pages/week-09.md) |
| [10](week-10-procedures-triggers/) | Procedures and triggers | `score_transaction`, triggers, event, `transfer_funds` | [p.10](report/pages/week-10.md) |
| [11](week-11-final-polish/) | Final | 27 pytest tests, report/slides/demo/viva material, limitations | [p.11](report/pages/week-11.md) |

## Run it

Needs Docker (MySQL 8.4 image) — or your own MySQL 8.0.31+ (set `DB_HOST=127.0.0.1`).

```bash
make up                 # start MySQL
make week N=5           # database exactly as it was at the end of week 5, then run that week's checks
make all                # the finished project (weeks 1-10) + 98 automated assertions
make shell              # a mysql prompt on the finished database
make test               # pytest (27 tests)
```

`scripts/build.sh N` loads weeks 1..N; `scripts/check.sh N` verifies them. The 90-second demo is `week-10-procedures-triggers/demo/01_fraud_demo.sql`.

## Also in here
* [`AGENTS.md`](AGENTS.md) — briefing for any AI assistant or new teammate picking the project up.
* [`CHANGES_FROM_ORIGINAL.md`](CHANGES_FROM_ORIGINAL.md) — what was fixed or changed relative to the first single-commit version, with evidence.
* [`docs/LAB_EXAM_CHEATSHEET.md`](docs/LAB_EXAM_CHEATSHEET.md) — MySQL syntax for lab experiments 1-9.
* [`week-11-final-polish/docs/`](week-11-final-polish/docs/) — viva Q&A, limitations, performance numbers, demo script.

The first, single-commit version of the project: https://github.com/SAI-HARISH2007/sentinel-sql
Licence: MIT.
