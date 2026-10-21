# AGENTS.md — briefing for any AI assistant (Copilot, ChatGPT, …) or new teammate

Read this fully before touching anything. You are helping a **second-year B.Tech student** finish and *understand* a DBMS mini-project. He may lose access to the assistant who built this, so you are the continuity.

## The project in one paragraph
`sentinel` is a MySQL 8 database. `INSERT INTO transactions` fires trigger `trg_after_txn_insert`, which `CALL`s `score_transaction(txn_id)`; six rules (z-score amount, off-hours, new device, velocity, impossible travel, merchant risk) each add one point and a reason; any score > 0 writes a row to `alerts` (`reasons` is a JSON array). All thresholds live in table `rule_config`.

## Why the repo is "week by week"
The faculty wants progress in step with the labs. Each `week-NN-*` folder is one lab experiment (order from the 2026-27 handout: 1 DDL, 2 constraints, 3 DML, 4 functions, 5 operators, 6 joins, 7 group/having/order, 8 views+indexes, 9 procedures+triggers; week 1 = intro + ER). **Week N may only depend on weeks < N.** The same fraud rules reappear in each week in a more advanced packaging: by-hand query (wk 5) → join (7) → group/having (8) → view (9) → procedure fired by a trigger (10).

## Layout
```
week-NN-*/sql/        loaded by scripts/build.sh, in filename order. These ARE the project.
week-NN-*/queries/    run by hand; kept as the week's lab material (must run without error)
week-NN-*/demo/       self-cleaning demos. Files named *violation* are SUPPOSED to raise errors ("-- EXPECT ERROR" marks each)
week-NN-*/lab-practice/  solutions to the lab manual's own assignments, in a separate database `lab_practice`
week-NN-*/check.sql   assertions; every row must say PASS
week-NN-*/README.md   the explanation + viva concepts
scripts/              build.sh N · check.sh N · compare_to_reference.sh · gen_er_docs.py · build_report.py · fingerprint.sql
reference/            frozen schema fingerprint of the finished database
report/               generated report pages (do not hand-edit; run scripts/build_report.py)
```

## Commands you will need
```bash
make up && make all            # build weeks 1-10 and run ALL checks (must end "failed: 0")
make week N=6                  # state as of week 6
make test                      # pytest, 27 tests
scripts/compare_to_reference.sh        # schema unchanged?   (--update after a DELIBERATE schema change)
python3 scripts/gen_er_docs.py         # regenerate ER docs after a schema change
python3 scripts/build_report.py        # regenerate report/*.md (needs the finished DB running)
python3 scripts/build_pdf.py           # md -> PDF (pip install markdown weasyprint)
```
Env overrides: `CONTAINER`, `DB_ROOT_PASS`, `DB_HOST`/`DB_PORT` (host mode). Dev passwords are in `docker-compose.yml`; they protect nothing real.

## Rules for you
1. **Teach, don't just fix.** The student is graded in a **viva** and a closed-book lab. For any non-trivial change, explain it so he could say it aloud. Point at the week's README "Concepts" and `week-11-final-polish/docs/viva_questions.md`.
2. **Never claim what you have not run.** Run `make all` after any SQL change. Quote real output. Do not invent benchmark numbers (an earlier version did; see `CHANGES_FROM_ORIGINAL.md`).
3. **Keep the week ordering.** New SQL goes in the week where its lab topic is taught. If you add a file, add its assertions to that week's `check.sql`, and make sure later weeks' checks still pass (assertions must stay true after Week 10: do not assert "alerts is empty").
4. **Do not rewrite git history or fake commit dates.** Faculty can see them. See `GIT_COMMANDS.md`.
5. **MySQL 8 only.** Use `RENAME COLUMN a TO b`, `MODIFY col TYPE` — NO Oracle-style brackets or `VARCHAR2`. See `docs/LAB_EXAM_CHEATSHEET.md`.
6. Always run the mysql client with `--default-character-set=utf8mb4` (the scripts do). Latin1 breaks string comparisons against the views.
7. Inside a trigger use `USER()` for "who did this" — `CURRENT_USER()` returns the definer.
8. Load bulk data **before** installing the scoring trigger; with it on, 12,000 inserts take minutes.
9. Seed data is deterministic and committed (`week-04-dml/sql/20_seed_data.sql`). Persona transactions are ids 12041-12067. Many checks hard-code counts; if you regenerate the seed, update them.

## Known behaviours that look like bugs but are not
`week-11-final-polish/docs/limitations.md` — random cities in the synthetic data cause ~32 background "impossible travel" hits; z-score on skewed amounts flags 1.2 %; the off-hours rule is weak below 50 transactions; merchant risk feeds on other rules' alerts (guarded by `merchant_risk_min_alerts = 3`).

## Hand-over prompt (paste into the assistant)
> I am Sai Haresh, ICFAI B.Tech Sem 3. Read AGENTS.md, README.md and PROGRESS.md in this repo. We are on **week ___**. Run `make all` and tell me the result. Then help me with: ___. Explain as if I must defend it in a viva tomorrow, and never claim output you have not run.
