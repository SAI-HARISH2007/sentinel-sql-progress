# Performance — what was measured

All numbers: MySQL 8.4.11 in Docker on a laptop, 12,067 transactions. Milliseconds depend on your machine; the *ratios and plan shapes* are what matter.

## Indexes (Week 9)
Full explanation and raw `EXPLAIN ANALYZE` output: [`../../week-09-views-indexes-dcl/docs/benchmark_measured.md`](../../week-09-views-indexes-dcl/docs/benchmark_measured.md).

* Date-range report: **Table scan, cost 1349 → Index range scan, cost 174** (≈ 8× cheaper).
* One account's latest 50 rows: the composite index only removes a *Sort* step. On ~52 rows per account the saving is microseconds.

## The cost of the trigger (Week 10)
1,000 inserts into `transactions`, measured inside a rolled-back transaction:

| | Time for 1,000 rows | Per row |
|---|---|---|
| Trigger dropped | ≈ 41 ms | ≈ 0.04 ms |
| Trigger active (scores every row) | ≈ 1,980 ms | ≈ 2 ms |

So scoring makes each insert about **50× slower**, yet still ≈ **500 transactions per second** on a laptop. That is the trade-off of doing the check inside the database: no race window and no extra system, paid for with write latency.

## Why the load order matters
Loading the 12,067-row seed with the trigger already installed (as the original repository did) was only ~half finished (5,925 rows) after 250 seconds. Loading the data first and installing the trigger afterwards (Weeks 4 → 10) takes about 20 seconds for weeks 1–9.

## Back-filling history
`CALL backfill_alerts(1, 12067)` scores every historical transaction in **38 seconds** and creates **634** alerts (≈ 5 %).
