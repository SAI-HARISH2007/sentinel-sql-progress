# Index benchmark — measured, not assumed

**Where this came from:** `demo/explain_before_after.sql`, run on MySQL 8.4.11 in Docker with the 12,067-row seed.
Re-run it on your own machine; the *shape* of each plan will match, the milliseconds will not.
(Earlier versions of this project carried a hand-written "expected" benchmark. It was never measured, so it was replaced by this file.)

## What the numbers say

| Query | Without the index | With the index | Verdict |
|---|---|---|---|
| Date-range report over 6 days (`idx_txn_time`) | **Table scan**, reads all 12,067 rows, optimiser cost **1349** | **Index range scan**, reads only the 315 matching rows, cost **174** | Clear win: about 8x cheaper by cost. |
| Latest 50 transactions of account 1 (`idx_txn_account_time`) | index lookup on `account_id`, **then a Sort** step | index lookup that already returns rows in time order, **no Sort** | Real but tiny: an account has only ~52 rows, so sorting them costs microseconds. It would matter for accounts with millions of rows. |
| Merchant 50, newest 20 (`idx_txn_merchant_time`) | (not measured) | index lookup in reverse time order, stops after 20 rows | Same effect as above. |

**Be honest about this in the viva:** on a 12,000-row table almost everything is fast. Indexes matter most for
range scans over a large share of the table (the first row) and will matter much more at 12 million rows.
The *plan change* (Table scan -> Index range scan, Sort removed) is the evidence; the milliseconds are not.

## Raw output

```
step: --- 1a. BEFORE: no index on txn_time

EXPLAIN: -> Aggregate: count(0), sum(transactions.amount)  (cost=1349 rows=1) (actual time=2.06..2.06 rows=1 loops=1)
    -> Filter: ((transactions.txn_time >= TIMESTAMP'2026-08-15 00:00:00') and (transactions.txn_time < TIMESTAMP'2026-08-21 00:00:00'))  (cost=1217 rows=1325) (actual time=0.0684..2.04 rows=315 loops=1)
        -> Table scan on transactions  (cost=1217 rows=11924) (actual time=0.0616..1.03 rows=12067 loops=1)

step: --- 1b. AFTER: idx_txn_time

EXPLAIN: -> Aggregate: count(0), sum(transactions.amount)  (cost=174 rows=1) (actual time=0.452..0.452 rows=1 loops=1)
    -> Index range scan on transactions using idx_txn_time over ('2026-08-15 00:00:00' <= txn_time < '2026-08-21 00:00:00'), with index condition: ((transactions.txn_time >= TIMESTAMP'2026-08-15 00:00:00') and (transactions.txn_time < TIMESTAMP'2026-08-21 00:00:00'))  (cost=142 rows=315) (actual time=0.21..0.427 rows=315 loops=1)

step: --- 2a. BEFORE: index on account_id only

EXPLAIN: -> Limit: 50 row(s)  (cost=18.2 rows=50) (actual time=0.0989..0.104 rows=50 loops=1)
    -> Sort: transactions.txn_time DESC, limit input to 50 row(s) per chunk  (cost=18.2 rows=52) (actual time=0.0981..0.101 rows=50 loops=1)
        -> Index lookup on transactions using fk_txn_account (account_id=1)  (cost=18.2 rows=52) (actual time=0.0661..0.0703 rows=52 loops=1)

step: --- 2b. AFTER: composite (account_id, txn_time)

EXPLAIN: -> Limit: 50 row(s)  (cost=18.2 rows=50) (actual time=0.085..0.0936 rows=50 loops=1)
    -> Index lookup on transactions using idx_txn_account_time (account_id=1) (reverse)  (cost=18.2 rows=52) (actual time=0.0838..0.089 rows=50 loops=1)

step: --- 3. merchant 50, newest first

EXPLAIN: -> Limit: 20 row(s)  (cost=88.5 rows=20) (actual time=0.227..0.231 rows=20 loops=1)
    -> Index lookup on transactions using idx_txn_merchant_time (merchant_id=50) (reverse)  (cost=88.5 rows=253) (actual time=0.227..0.229 rows=20 loops=1)
```
