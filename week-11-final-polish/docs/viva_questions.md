# Viva questions — with answers you can say out loud

Grouped by the week you learned them. If you cannot answer a question in two sentences, open that week's README and the file it points to. Answers are about *this* project wherever possible: examiners reward "in our project…".

## Design (Week 1, 3)
**1. Why a database instead of files?** Files give no integrity rules, no concurrent-access control, no security model and force every program to know the layout. A DBMS centralises all four and gives *data independence*.
**2. Entity vs entity set vs attribute?** An entity is one thing (account 1); an entity set is all of them (`accounts`); an attribute describes it (`balance`).
**3. How did you turn the M:N relationship into tables?** Account–Device is many-to-many, so it became its own table `account_devices` with both foreign keys; the pair `(account_id, device_id)` is the primary key. `first_seen` and `last_seen` describe the *relationship*, so they live there.
**4. 1:1 relationship in your schema?** `alerts.txn_id` and `behaviour_baselines.account_id`: a foreign key that is also `UNIQUE`.
**5. Primary key vs unique key vs candidate key?** Candidate keys are all minimal unique identifiers (`email`, `fingerprint_hash`, the id). One is chosen as primary (no NULLs, one per table); the others stay `UNIQUE`.
**6. Why integer ids instead of the email as key?** Smaller foreign keys and indexes, and an email can change. The email stays `UNIQUE`.
**7. Is the schema in 3NF? Prove one table.** Yes. In `transactions` every non-key column depends on `txn_id` only: the whole key (2NF, trivially, because the key is one column) and nothing but the key (3NF: nothing like "city → state" inside the table; that lives in `locations`).
**8. Where did you deliberately break normal form?** `behaviour_baselines` stores *derived* statistics (average, hours as JSON) as a controlled cache, refreshed nightly.
**9. CASCADE vs RESTRICT: why each?** Deleting a user removes their accounts and transactions (meaningless without the owner → CASCADE). You cannot delete a merchant/device/location that transactions still reference (history must not silently vanish → RESTRICT).
**10. What does CHECK do and since which version?** Rejects rows violating a condition (`amount > 0`). Enforced from MySQL 8.0.16; older versions parsed and ignored it.

## SQL language (Weeks 2, 4–8)
**11. DDL vs DML vs DCL vs TCL vs DRL?** Define structure (CREATE/ALTER/DROP) · change data (INSERT/UPDATE/DELETE) · permissions (GRANT/REVOKE) · transactions (COMMIT/ROLLBACK) · query (SELECT).
**12. DELETE vs TRUNCATE vs DROP?** DELETE removes chosen rows, can be rolled back, fires triggers. TRUNCATE empties the table, resets AUTO_INCREMENT, is DDL (implicit commit, no rollback). DROP removes rows *and* the table.
**13. Why did you add constraints with ALTER rather than in CREATE TABLE?** To follow the labs in order: Week 2 creates bare tables, Week 3 adds each constraint. The finished tables are identical to declaring everything inline in `CREATE TABLE` (we compared the result column-by-column and constraint-by-constraint against the first version of the project).
**14. `COUNT(*)` vs `COUNT(col)`?** `COUNT(*)` counts rows; `COUNT(col)` skips NULLs. All aggregate functions except `COUNT(*)` ignore NULL.
**15. Why `IS NULL` and never `= NULL`?** NULL is "unknown"; `NULL = NULL` is unknown, not true. `<=>` is the NULL-safe equals.
**16. `AND` / `OR` precedence?** AND binds tighter. In our demo, adding brackets changed 1,300 rows to 148.
**17. UNION vs UNION ALL? INTERSECT, EXCEPT?** UNION removes duplicates (sorts), UNION ALL keeps them (faster). INTERSECT = in both, EXCEPT = in the first not the second (Oracle: MINUS).
**18. Inner vs left vs right vs full join?** Inner: matching pairs only. Left: all left rows, NULLs where no match. Right: mirror. Full: both; MySQL has none, so `LEFT JOIN UNION RIGHT JOIN`.
**19. How do you find "rows with no match"?** `LEFT JOIN … WHERE right.key IS NULL` (anti-join). We used it for Rule 3 (new device).
**20. Why is NATURAL JOIN risky?** It joins on every same-named column; add a column later and the join silently changes. `merchants NATURAL JOIN locations` returned 0 rows because three names coincide.
**21. When did you need a self join?** Velocity: compare each transaction with the same account's transactions in the next 5 minutes.
**22. WHERE vs HAVING?** WHERE filters rows before grouping; HAVING filters groups after aggregation, so only HAVING may contain `COUNT(*)`.
**23. Order in which a SELECT runs?** FROM/JOIN → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT. This is why a WHERE cannot use a SELECT alias.
**24. Types of subquery you used?** Scalar (`> (SELECT AVG…)`), `IN`, `EXISTS`, correlated (per-row), derived table (in FROM). Our Rule 1 uses a derived table.
**25. `NOT IN` vs `NOT EXISTS`?** `NOT IN` returns nothing if the list contains a NULL; `NOT EXISTS` is safe.

## Views, indexes, security (Week 9)
**26. What is a view, and why use one?** A stored SELECT, no data of its own. Names a rule, centralises logic, and lets us grant access to the view without the tables.
**27. Can you update through a view?** Only simple ones (single table, no GROUP BY/aggregates/DISTINCT). Ours are read-only.
**28. View vs materialised view?** A view is recomputed on every query. A materialised view stores the result; MySQL has none (we use the `behaviour_baselines` table refreshed by an event instead).
**29. What is an index and what does it cost?** A sorted structure (B+ tree) that lets MySQL jump to rows. Cost: space and slower writes (we measured 2 ms per insert with the trigger; indexes add to it).
**30. Composite index `(account_id, txn_time)`: when is it used?** For filters on `account_id`, or `account_id` and `txn_time` (leftmost-prefix rule), and it also returns rows already sorted by time. It is *not* used for a filter on `txn_time` alone.
**31. Clustered vs secondary index?** In InnoDB the table *is* the primary-key B+ tree (clustered); every other index is secondary and stores the primary key as its pointer.
**32. Why did you not index `alerts.txn_id`?** It is `UNIQUE`, which already is an index.
**33. How do you prove an index helps?** `EXPLAIN ANALYZE`. Ours: table scan cost 1349 → range scan cost 174 for a date-range report.
**34. GRANT, REVOKE, role?** GRANT gives a privilege, REVOKE takes it away, a role is a named bundle. `fraud_analyst` reads views only; `txn_app` only inserts.
**35. Why can the analyst read a view of a table they cannot read?** Views run with the *definer's* rights (`SQL SECURITY DEFINER`).

## Programmability and transactions (Week 10)
**36. Procedure vs function?** A function returns one value and is used inside expressions (`haversine_km`); a procedure is `CALL`ed, can return result sets and modify data (`score_transaction`).
**37. What is a trigger? BEFORE vs AFTER? OLD and NEW?** Code the database runs on INSERT/UPDATE/DELETE. BEFORE can change `NEW` before it is stored (we stamp `reviewed_at`); AFTER sees the stored row (we score it). `NEW` is the incoming row, `OLD` the previous one.
**38. Why is the scoring trigger AFTER INSERT?** The procedure reads the transaction, which does not exist yet in a BEFORE trigger.
**39. Why `USER()` and not `CURRENT_USER()` in the audit trigger?** Inside a trigger `CURRENT_USER()` returns the trigger's definer (root); `USER()` returns the person who actually connected.
**40. State the ACID properties with an example from your project.** Atomicity: `transfer_funds` debits and credits together or not at all. Consistency: balance never negative (CHECK + procedure). Isolation: `SELECT … FOR UPDATE` makes a concurrent update wait (our 5-second demo). Durability: after COMMIT it survives a crash (redo log).
**41. How did you avoid deadlock?** Rows are always locked in ascending `account_id` order, so two opposite transfers cannot each hold what the other needs.
**42. What does the EXIT HANDLER do?** On any SQL error it rolls back and re-raises, so a half-finished refresh/transfer cannot be left behind.
**43. What is an EVENT?** A scheduled job inside MySQL; ours refreshes the baselines nightly at 02:30 (needs `event_scheduler=ON`).
**44. Why put the fraud check in the database?** No application can forget to run it, no race window between commit and check, thresholds are data. Cost: write latency (≈ 2 ms per insert) and logic that is harder to unit-test than app code.

## Honest-engineering questions (they will ask)
**45. What are the weaknesses of your detector?** See `limitations.md`: random cities in the data, a z-score on skewed amounts, the off-hours rule on short histories, a merchant-risk feedback loop.
**46. How do you know it works?** Five planted personas each fire the intended rule (`week-10/check.sql`), one ordinary payment produces no alert, and a live trigger test runs inside a rolled-back transaction.
**47. What would you change with more time?** Home cities per account; baseline from earlier transactions only; scoring merchants from confirmed fraud; a `txn_type` column.
**48. What did you change from your first version and why?** See `CHANGES_FROM_ORIGINAL.md`: the first version's nightly job and audit trigger never got created (a syntax error aborted the file), the night-owl persona could never fire, and loading data with the trigger on took minutes.
