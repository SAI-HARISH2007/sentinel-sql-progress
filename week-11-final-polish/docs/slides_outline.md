# Slide deck outline (10–12 slides)

1. **Title** — Sentinel: fraud detection inside the database. Names, course, date.
2. **The problem** — Fraud checks usually live in app code: hard-coded, late, duplicated data. One sentence: *can the database itself notice?*
3. **What we built** — One diagram: `INSERT → trigger → score_transaction → alerts`. Six rules listed.
4. **Data model** — The ER diagram (draw it in class notation). 13 tables, 3NF.
5. **Integrity by design** — Keys, CHECK, FK actions. Screenshot of a violation being refused.
6. **Same idea, four packagings** — Rule 4 (velocity) as a query (Wk 7/8) → view (Wk 9) → procedure (Wk 10) → fired by a trigger. This is the slide that shows the *course* in one picture.
7. **Live demo** — the 90-second demo. (If the laptop fails: screenshot of the alert.)
8. **Control** — Roles/GRANT/REVOKE: analyst can read views, not tables; audit trail records who.
9. **Transactions** — `transfer_funds`: ACID, ordered locking, refusal cases.
10. **Performance** — measured: index plan change; trigger cost 2 ms/row. Honest about size.
11. **What it can't do** — three limitations from `limitations.md` (random cities, skewed z-score, feedback loop).
12. **Weekly journey + thanks** — one line per week from `PROGRESS.md`.

Rule: ≤ 6 lines of text per slide. Screenshots over bullet points.
