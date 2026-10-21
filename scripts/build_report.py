#!/usr/bin/env python3
"""Build the project report from the week folders.

    python3 scripts/build_report.py            # needs the finished database (scripts/build.sh 10) running

For every week it writes   report/pages/week-NN.md        (that week's report page, with REAL query output embedded)
and a growing report       report/PROJECT_REPORT_through_week_N.md   (cover + pages 1..N)
plus the final             report/PROJECT_REPORT.md        (all weeks)

Output is captured by running the week's own scripts against the live database, so the report cannot drift from the code.
Env: CONTAINER / DB_ROOT_PASS / DB_HOST as for the other scripts.
"""
import os, re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTAINER = os.getenv("CONTAINER", "sentinel-db")
PW = os.getenv("DB_ROOT_PASS", "sentinel_root_2026")

def mysql(sql_text, table=True):
    if os.getenv("DB_HOST"):
        cmd = ["mysql", "-h", os.environ["DB_HOST"], "-uroot", "--default-character-set=utf8mb4"]
        env = dict(os.environ, MYSQL_PWD=PW)
    else:
        cmd = ["docker", "exec", "-i", "-e", f"MYSQL_PWD={PW}", CONTAINER, "mysql", "-uroot", "--default-character-set=utf8mb4"]
        env = os.environ
    if table: cmd.append("-t")
    r = subprocess.run(cmd, input=sql_text, capture_output=True, text=True, env=env)
    out = (r.stdout + r.stderr).replace("mysql: [Warning] Using a password on the command line interface can be insecure.\n", "")
    return out.strip()

# (week folder, [(caption, file relative to week folder, max lines)])  -- files that are safe to run (self-cleaning / read-only)
SHOW = {
 1: [("Database and character set", "demo/01_mysql_basics.sql", 30)],
 2: [("Every DDL command on a throw-away table", "demo/ddl_tour.sql", 60)],
 3: [("Constraints firing (errors are the expected result)", "demo/constraint_violations.sql", 40)],
 4: [("INSERT / UPDATE / DELETE tour", "demo/dml_tour.sql", 70)],
 5: [("Rule 1 by hand: the 95,000 payment", "queries/05_rule1_high_amount.sql", 20),
     ("Rule 5 by hand: Delhi to Chennai in 10 minutes", "queries/07_rule5_impossible_travel_by_hand.sql", 12)],
 6: [("Set operators", "queries/05_set_operators.sql", 45), ("First-cut fraud screen", "queries/06_first_cut_fraud_screen.sql", 30)],
 7: [("Seven-table join: the whole story of one payment", "queries/01_inner_join.sql", 12),
     ("Rule 3: new device", "queries/05_rule3_new_device.sql", 28)],
 8: [("Rule 4 (velocity) complete", "queries/02_having.sql", 30), ("Rule 1 for all accounts", "queries/05_rule1_high_amount_all_accounts.sql", 20),
     ("Rule 6 stand-in", "queries/07_rule6_merchant_risk.sql", 16)],
 9: [("Index experiment: EXPLAIN ANALYZE", "docs/benchmark_measured.md", 0)],
 10: [("The 90-second demo", "demo/01_fraud_demo.sql", 90), ("Transactions: rollback and transfer_funds", "demo/02_transaction_demo.sql", 60),
      ("Refused transfers (errors are the expected result)", "demo/03_transfer_failures_violation.sql", 25)],
 11: [("Whole-project invariants", "check.sql", 30)],
}

def run_file(week_dir, rel, maxlines):
    p = week_dir / rel
    if rel.endswith(".md"):
        return None
    text = p.read_text(encoding="utf-8")
    if "violation" in rel:
        # tolerate expected errors
        out = subprocess.run(
            (["mysql", "-h", os.environ["DB_HOST"], "-uroot", "--force", "-t"] if os.getenv("DB_HOST")
             else ["docker", "exec", "-i", "-e", f"MYSQL_PWD={PW}", CONTAINER, "mysql", "-uroot", "--force", "-t", "--default-character-set=utf8mb4"]),
            input=text, capture_output=True, text=True, env=dict(os.environ, MYSQL_PWD=PW))
        o = (out.stdout + out.stderr).replace("mysql: [Warning] Using a password on the command line interface can be insecure.\n", "").strip()
    else:
        o = mysql(text)
    lines = o.splitlines()
    if maxlines and len(lines) > maxlines:
        lines = lines[:maxlines] + [f"... ({len(o.splitlines()) - maxlines} more lines)"]
    return "\n".join(l[:170] for l in lines)

def week_dirs():
    return sorted(ROOT.glob("week-[0-9][0-9]-*"))

def clean_readme(text):
    text = re.sub(r"\n## Push checklist.*", "\n", text, flags=re.S)
    text = re.sub(r"\n## Watch out.*?(?=\n## )", "\n", text, flags=re.S)
    text = re.sub(r"\n## Try it yourself.*?(?=\n## )", "\n", text, flags=re.S)
    text = re.sub(r"\n## Run it.*?(?=\n## What you should see)", "\n", text, flags=re.S)
    text = re.sub(r"\[← Week.*?\n", "\n", text)
    text = text.replace("](../", "](../../")
    text = text.replace("## What you add this week", "## What was added").replace("## Where this goes in the final report", "## Handout step covered")
    return text.strip()

cover = """# Sentinel — In-Database Real-Time Fraud Detection System
### Database Management Systems (CS/AI/AIM/DS 202) — Mini Project Report


**Institution:** ICFAI Foundation for Higher Education, Faculty of Science & Technology, Hyderabad

**Programme:** B.Tech CSE (AI & ML), Semester III, A.Y. 2026-27

**Team:** Sai Haresh Anand S · Seshivardhini

**Repository:** https://github.com/SAI-HARISH2007/sentinel-sql-progress
**Database:** MySQL 8.4 (Docker)

## Abstract
Fraud checks usually live in application code: hard-coded thresholds, a gap between commit and check, and a separate copy of the data.
Sentinel moves the check *into the database*. A trigger on `INSERT INTO transactions` calls a stored procedure that scores the new row against
six rules (high amount, off-hours, new device, velocity, impossible travel, merchant risk), each measured against that account's own history,
and writes an alert with human-readable reasons. Thresholds live in a table, so tuning is an `UPDATE`.

The report is organised **week by week**, following the course's lab sequence. Each page was added in the week the matching lab was done,
and every query result shown was captured by running the repository's own scripts on the finished database.

| Week | Lab topic | Adds to the project |
|---|---|---|
"""
rows, pages = [], {}
for d in week_dirs():
    n = int(re.match(r"week-0*(\d+)-", d.name).group(1))
    readme = (d / "README.md").read_text(encoding="utf-8")
    title = re.search(r"# Week \d+ — (.*)", readme).group(1)
    summ = re.search(r"\n\n(?:\*\*Lab:\*\*.*?\n\*\*Theory.*?\n\n)(.*?)\n\n", readme, flags=re.S)
    rows.append(f"| {n} | {title} | {(summ.group(1) if summ else '').split('. ')[0].strip().rstrip('.')}. |")
    body = clean_readme(readme)
    extra = []
    for caption, rel, mx in SHOW.get(n, []):
        if rel.endswith(".md"):
            md = (d / rel).read_text(encoding="utf-8")
            extra.append(f"### Evidence: {caption}\n\nSee [`{rel}`](../../{d.name}/{rel}) for the full measured output. Key result:\n\n"
                         + "\n".join(l for l in md.splitlines() if l.startswith("|"))[:1500] + "\n")
            continue
        out = run_file(d, rel, mx)
        extra.append(f"### Evidence: {caption}\n\nScript: [`{d.name}/{rel}`](../../{d.name}/{rel})\n\n```text\n{out}\n```\n")
    page = f"{body}\n\n## Results (captured from the running database)\n\n" + "\n".join(extra) + "\n\n---\n"
    pages[n] = page
    (ROOT / "report" / "pages" / f"week-{n:02d}.md").write_text(page, encoding="utf-8")

cover += "\n".join(rows) + "\n\n---\n\n"
for n in sorted(pages):
    through = cover + "\n".join(pages[k] for k in sorted(pages) if k <= n)
    (ROOT / "report" / f"PROJECT_REPORT_through_week_{n}.md").write_text(through, encoding="utf-8")
(ROOT / "report" / "PROJECT_REPORT.md").write_text(cover + "\n".join(pages[k] for k in sorted(pages)), encoding="utf-8")
print("report built:", len(pages), "pages")
