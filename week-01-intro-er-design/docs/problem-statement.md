# Sentinel — problem statement, objectives, requirements

*(Mini-project steps 1–4 in the course handout: title, problem statement, objectives, requirements gathering.)*

## 1. Title
**Sentinel — In-Database Real-Time Fraud Detection System**

## 2. Problem statement
Digital payments (UPI, cards, wallets) are attacked constantly. In most systems the fraud check lives in
application code that runs *around* the database. That has three weaknesses:

* thresholds are hard-coded, so changing one needs a code deploy;
* the transaction is already committed before the check runs, so a fraudulent row exists for a while;
* a separate fraud system needs its own copy of the data and a pipeline to feed it.

**Question this project answers:** can the database itself notice a suspicious transaction the moment
it is inserted — using only SQL features taught in this course — and explain why?

## 3. Objectives
1. Model users, accounts, merchants, devices, locations, transactions and alerts as a clean relational schema.
2. Keep the schema in 3NF with every integrity rule (keys, NOT NULL, CHECK, FK actions) enforced *by the database*.
3. Express six fraud rules as plain SQL, then package them progressively as queries → views → a stored procedure.
4. Fire the procedure automatically from a trigger on `INSERT INTO transactions`.
5. Keep all thresholds in a table (`rule_config`) so tuning the detector is an `UPDATE`.
6. Show transaction control (`COMMIT`/`ROLLBACK`, row locks) and least-privilege access (roles, `GRANT`/`REVOKE`).

## 4. Requirements
**Functional**

| ID | Requirement | Built in |
|----|-------------|----------|
| FR-1 | Store users, accounts, merchants, devices, locations, transactions | Weeks 2–4 |
| FR-2 | Six independent fraud rules, each with a human-readable reason | Weeks 5–8 (queries), Week 9 (views) |
| FR-3 | Per-user behaviour baseline (average amount, usual hours, usual cities) | Week 8, refreshed nightly in Week 10 |
| FR-4 | Every new transaction is scored automatically; suspicious ones land in `alerts` | Week 10 |
| FR-5 | Thresholds live in `rule_config` | Week 4 |
| FR-6 | Analysts can read alerts but cannot touch raw data | Week 9 (roles) |
| FR-7 | Money transfer is all-or-nothing | Week 10 (`transfer_funds`) |

**Non-functional**
* Every SQL file can be re-run safely (`DROP … IF EXISTS` at the top).
* Query speed on 12,000+ transactions stays interactive (indexes — Week 9).
* Cost ₹0: MySQL 8 + Docker + Python only for generating fake data.

## 5. The six fraud signals

| # | Signal | Idea | SQL ideas it exercises |
|---|--------|------|------------------------|
| 1 | High amount | amount is far above this account's usual (z-score) | aggregate functions, subquery |
| 2 | Off-hours | hour of day this account almost never transacts in | date functions, GROUP BY |
| 3 | New device | device never seen on this account before | LEFT JOIN … IS NULL |
| 4 | Velocity | too many transactions in a few minutes | self-join, GROUP BY / HAVING |
| 5 | Impossible travel | two cities, too far apart for the time between them | number functions, window function `LAG` |
| 6 | Merchant risk | merchant whose alert rate is far above the platform average | GROUP BY / HAVING, subquery |

## 6. Out of scope
Real payment gateways, machine learning, login screens, cloud deployment.
