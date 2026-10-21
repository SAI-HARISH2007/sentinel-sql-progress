# Demo script (5 minutes). Practise it twice with a stopwatch.

**Setup (before the examiner arrives):** `make up && make all`. Open MySQL Workbench on `sentinel`, with `week-10.../demo/01_fraud_demo.sql` loaded. Have the screenshots ready in case the database is down.

| Time | Say | Do |
|---|---|---|
| 0:00 | "Fraud checks usually live in app code. Ours lives in the database, so no application can forget to run it." | Show the one-picture architecture slide. |
| 0:30 | "Here is a normal customer: shops 9 to 6, Mumbai, one device." | Run block 1 of `01_fraud_demo.sql`. |
| 1:00 | "Now a ₹95,000 payment at 3 a.m. from a device this account has never used." | Run block 2 (the `INSERT`). **Say nothing while it runs.** |
| 1:30 | "I called nothing. The trigger fired by itself." | Run block 3: the alert with three reasons. |
| 2:00 | "An analyst closes it; the database stamps the time and records *who*." | Blocks 4: `reviewed_at`, `audit_log` row. |
| 2:45 | "Thresholds are data, not code." | Block 5: raise the z-score threshold, "High amount" disappears, restore. |
| 3:15 | "Least privilege." | `bash week-09.../demo/dcl_demo.sh`: analyst denied on `transactions`, allowed on the view. |
| 4:00 | "All-or-nothing money." | `02_transaction_demo.sql` + show the four refused transfers. |
| 4:30 | "What it cannot do" | One limitation from `limitations.md` (say the random-city one). |
| 4:50 | "Everything is reproducible: `make all`, 98 assertions." | Show the green run. |

**If something breaks:** say what you expected to happen, show the screenshot, and carry on. Calm recovery scores higher than a flawless run that looks rehearsed.
