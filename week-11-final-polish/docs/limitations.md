# Known limitations (say these before the examiner does)

Every item below was observed on the real data, not guessed. Naming your own weaknesses precisely is the strongest thing you can do in a viva.

| # | Limitation | Evidence | Why it happens / what would fix it |
|---|---|---|---|
| 1 | **The background data is synthetic and unrealistic.** Every transaction gets a *random* city. | 33 impossible-travel pairs in the Week 7 self-join (46 in the Week 9 `LAG` view), of which only **one** is the planted traveller. | Real customers have a home city. Fix: give each account a home location and make 90 % of its transactions there. |
| 2 | **A z-score assumes a bell curve; payment amounts are skewed** (many small, few large). | 145 of 12,067 transactions (1.2 %) have z > 3, nearly all ordinary. | Use a robust measure (median + MAD), or a log of the amount. |
| 3 | **The off-hours rule is weak on short histories.** "Fewer than 2 % of history" can only be true when an account has more than 50 transactions. | Account 1 (52 transactions): hour 02 *and* hour 15 each hold 1/52 = 1.92 %, so a normal 3 p.m. purchase is also flagged. | Smooth the distribution, or require a minimum history. |
| 4 | **Rule 6 depends on alerts that other rules create** (a feedback loop). | The Week 10 burst demo, run with an unknown device, made *merchant 3* look risky. Before the `merchant_risk_min_alerts` guard, a merchant with a *single* alert was called risky and every one of its transactions flagged: the view returned 1,698 rows across several merchants. | Mitigated by requiring ≥ 3 alerts. A proper fix scores merchants from *confirmed* fraud only. |
| 5 | **Statistics include the transaction being scored.** The average and standard deviation for Rule 1 contain the 95,000 itself, which dampens its z-score. | Account 1: z = 6.97 with the payment included. | Compute the baseline from *earlier* transactions only (that is what `behaviour_baselines` is for). |
| 6 | **Only the 27 persona transactions are back-filled.** | `CALL backfill_alerts(1, 12067)` takes 38 s and would create 634 alerts. | Deliberate: keeps the demo readable. |
| 7 | **`transfer_funds` records only the sender's debit**, against a placeholder merchant (id 1). | `week-10.../sql/50_transfer_funds.sql` | A real design needs a `txn_type` column or a "transfer" pseudo-merchant. |
| 8 | **Passwords in the repo are for a local teaching database.** | `docker-compose.yml`, `40_roles_dcl.sql` | Never reuse them. Real systems read secrets from the environment. |
| 9 | **No user interface.** Everything is SQL. | — | Out of scope for a DBMS course; the *database* is the product. |
| 10 | **MySQL-specific.** `JSON`, `ENUM`, `CREATE OR REPLACE VIEW`, `EXPLAIN ANALYZE`, `INTERSECT`/`EXCEPT` (8.0.31+) are not portable to Oracle, which the lab manual's examples use. | — | See `docs/LAB_EXAM_CHEATSHEET.md` for the differences. |
