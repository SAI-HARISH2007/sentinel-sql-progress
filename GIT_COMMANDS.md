# GIT_COMMANDS.md — everything you type, and where

Repo: https://github.com/SAI-HARISH2007/sentinel-sql-progress
**Run every command from this folder** (the project root):
`C:\Users\saiha\Harish\ICFAI\ACADEMICS\SEMESTER_3\08_DBMS\sentinel-sql-progress`
In WSL that is `/mnt/c/Users/saiha/Harish/ICFAI/ACADEMICS/SEMESTER_3/08_DBMS/sentinel-sql-progress`. Use **Git Bash, WSL or PowerShell**: the commands are identical.

## ⚠️ Read once: dates and honesty
Git stamps each commit with the moment you run it. Running all eleven blocks today gives eleven commits dated today. **That is the truth, and that is what the faculty will see.** Do **not** fake dates (`GIT_AUTHOR_DATE`, rewriting history): GitHub shows the real push times, and it is academic misconduct risk.
To get a *genuine* weekly history, run **one block per lab, on the day you finish that lab**. Everything is already prepared, so each block takes a minute. If you must catch up, say so in `PROGRESS.md`.

## 0. One-time setup (once, ever)
```bash
cd /mnt/c/Users/saiha/Harish/ICFAI/ACADEMICS/SEMESTER_3/08_DBMS/sentinel-sql-progress    # WSL
# PowerShell / Git Bash:  cd C:\Users\saiha\Harish\ICFAI\ACADEMICS\SEMESTER_3\08_DBMS\sentinel-sql-progress

git config user.name  "SAI-HARISH2007"
git config user.email "saiharishanand2007@gmail.com"      # must be an email verified on your GitHub account
git init -b main
git remote add origin https://github.com/SAI-HARISH2007/sentinel-sql-progress.git
```
Log in when git asks (GitHub no longer accepts passwords: use the browser sign-in popup or a Personal Access Token).

## 1. Project scaffold (do this first, one commit)
Shared files that are not part of any week: README, AI briefing, scripts, CI, docs, cheat sheet.
```bash
git add README.md AGENTS.md PROGRESS.md CHANGES_FROM_ORIGINAL.md GIT_COMMANDS.md LICENSE .gitignore \
        Makefile docker-compose.yml scripts reference docs .github
git commit -m "Project scaffold: tooling, CI, docs, change log"
git push -u origin main
```

## 2. Weekly blocks
Each block adds that week's folder **plus its report page** and the report-so-far. Run block N after finishing lab N.

### Week 1
```bash
git add week-01-intro-er-design report/pages/week-01.md report/PROJECT_REPORT_through_week_1.md report/pdf/week-01.pdf report/pdf/PROJECT_REPORT_through_week_1.pdf
git commit -m "Week 1: problem statement, ER design, create database"
git push
```
### Week 2
```bash
git add week-02-ddl report/pages/week-02.md report/PROJECT_REPORT_through_week_2.md report/pdf/week-02.pdf report/pdf/PROJECT_REPORT_through_week_2.pdf
git commit -m "Week 2: DDL - create 13 tables, ALTER/RENAME/DROP COLUMN, lab practice"
git push
```
### Week 3
```bash
git add week-03-constraints report/pages/week-03.md report/PROJECT_REPORT_through_week_3.md report/pdf/week-03.pdf report/pdf/PROJECT_REPORT_through_week_3.pdf
git commit -m "Week 3: constraints - PK, FK, UNIQUE, NOT NULL, DEFAULT, CHECK, violation demos"
git push
```
### Week 4
```bash
git add week-04-dml report/pages/week-04.md report/PROJECT_REPORT_through_week_4.md report/pdf/week-04.pdf report/pdf/PROJECT_REPORT_through_week_4.pdf
git commit -m "Week 4: DML - rule_config, seed data (12,067 transactions + 5 fraud personas), lab practice"
git push
```
### Week 5
```bash
git add week-05-functions report/pages/week-05.md report/PROJECT_REPORT_through_week_5.md report/pdf/week-05.pdf report/pdf/PROJECT_REPORT_through_week_5.pdf
git commit -m "Week 5: functions - number/aggregate/string/date, Rule 1, Rule 2 preview, Rule 5 by hand"
git push
```
### Week 6
```bash
git add week-06-operators report/pages/week-06.md report/PROJECT_REPORT_through_week_6.md report/pdf/week-06.pdf report/pdf/PROJECT_REPORT_through_week_6.pdf
git commit -m "Week 6: operators - arithmetic/comparison/logical/special/set, first-cut fraud screen"
git push
```
### Week 7
```bash
git add week-07-joins report/pages/week-07.md report/PROJECT_REPORT_through_week_7.md report/pdf/week-07.pdf report/pdf/PROJECT_REPORT_through_week_7.pdf
git commit -m "Week 7: joins - inner/outer/natural/self, Rule 3 (new device), Rule 5 pairs"
git push
```
### Week 8
```bash
git add week-08-groupby-subqueries report/pages/week-08.md report/PROJECT_REPORT_through_week_8.md report/pdf/week-08.pdf report/pdf/PROJECT_REPORT_through_week_8.pdf
git commit -m "Week 8: GROUP BY/HAVING/ORDER BY + subqueries - Rules 1, 2, 4 complete; behaviour_baselines"
git push
```
### Week 9
```bash
git add week-09-views-indexes-dcl report/pages/week-09.md report/PROJECT_REPORT_through_week_9.md report/pdf/week-09.pdf report/pdf/PROJECT_REPORT_through_week_9.pdf
git commit -m "Week 9: views (6 rules + combined + reports), indexes with measured EXPLAIN, DCL roles"
git push
```
### Week 10
```bash
git add week-10-procedures-triggers report/pages/week-10.md report/PROJECT_REPORT_through_week_10.md report/pdf/week-10.pdf report/pdf/PROJECT_REPORT_through_week_10.pdf
git commit -m "Week 10: stored function/procedures, triggers, event, transfer_funds - fraud detection is live"
git push
```
### Week 11 (final) — also publishes the complete report
```bash
git add week-11-final-polish report/pages/week-11.md report/PROJECT_REPORT_through_week_11.md report/pdf/week-11.pdf report/pdf/PROJECT_REPORT_through_week_11.pdf report/PROJECT_REPORT.md report/PROJECT_REPORT.pdf
git commit -m "Week 11: tests, final project report, demo/viva material, limitations"
git push
```

## 3. Check before every push
```bash
git status                  # only the week you are pushing should be listed under "Changes to be committed"
git log --oneline           # one line per week, newest on top
```
CI (GitHub → Actions tab) rebuilds the database through the highest week present and runs its checks: a green tick on each week's commit is the faculty's proof it works.

## 4. What the faculty sees on the repo page
* `README.md` rendered, with the week table linking to each folder and each report page.
* A commit list with one commit per week (plus the scaffold).
* `report/PROJECT_REPORT.md`: the whole report, week by week, with real query output.

## 5. Updating a week after you pushed it
```bash
git add <the changed files>
git commit -m "Week N: fix <what> (found while doing <why>)"
git push
```
Never `git push --force` and never rewrite history.

## 6. Before you commit: regenerate the report if you changed any SQL
```bash
make up && make all                  # must end "failed: 0"
python3 scripts/build_report.py      # refreshes the .md report
python3 scripts/build_pdf.py         # refreshes every PDF (pip install markdown weasyprint)
```
