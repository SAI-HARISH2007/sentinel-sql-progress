# From the ER diagram to tables (logical design)

*(Lectures 7–9: "Entity sets to tables, relationship sets to tables, weak entity sets".)*
The ER diagram is in [`er-diagram.md`](er-diagram.md). This file records **which rule produced which table**,
which is exactly what a viva examiner asks.

| Rule | Where it was applied |
|------|----------------------|
| **Strong entity set → one table**, key attribute → primary key | `users`, `accounts`, `merchants`, `merchant_categories`, `devices`, `locations`, `transactions`, `alerts`, `rule_config`, `behaviour_baselines`, `login_history`, `audit_log` |
| **1 : N relationship → foreign key on the "many" side** | `accounts.user_id → users`, `transactions.account_id → accounts`, `transactions.merchant_id → merchants`, `transactions.device_id → devices`, `transactions.location_id → locations`, `merchants.category_id → merchant_categories`, `login_history.*` |
| **M : N relationship → its own table** holding both foreign keys, and any attributes of the relationship | `account_devices` (an account uses many devices; a device is used by many accounts) — carries `first_seen`, `last_seen`; primary key is the pair `(account_id, device_id)` |
| **1 : 1 relationship → foreign key + UNIQUE** | `alerts.txn_id UNIQUE → transactions` (a transaction has at most one alert); `behaviour_baselines.account_id UNIQUE → accounts` |
| **Total participation → NOT NULL on the foreign key** | every `transactions.*_id` is `NOT NULL`: a transaction cannot exist without an account, merchant, device and location |
| **Partial participation → nullable** | `alerts.reviewed_at` is NULL until an analyst reviews the alert |
| **Derived attribute** | `behaviour_baselines` stores *derived* statistics (average, standard deviation, usual hours). This is deliberate, controlled redundancy: recomputing them on every insert would be slow. They are rebuilt nightly (Week 10 event). |
| **Weak entity set** | None is strictly needed. `login_history` *could* be modelled as a weak entity of `accounts`, but we give it its own surrogate key `login_id`, which makes it a strong entity. Be ready to say this if asked. |
| **Multi-valued attribute** | "Hours this account is active" and "cities this account uses" are multi-valued, so they cannot sit in one atomic column (1NF). They are stored as JSON arrays inside `behaviour_baselines` *because they are derived caches, never queried by value*. If they were base data they would need their own table. |

## Why a surrogate key (`*_id INT AUTO_INCREMENT`) everywhere?
`email`, `fingerprint_hash`, `(city, country)` are *candidate keys* — each is unique and could be the primary key.
We keep them as `UNIQUE` and choose a small integer as the primary key because it is compact in every foreign key and in every index.

## Cardinalities at a glance

| Relationship | Cardinality |
|---|---|
| user — owns — account | 1 : N |
| account — makes — transaction | 1 : N |
| merchant — receives — transaction | 1 : N |
| device / location — used in — transaction | 1 : N each |
| account — uses — device | **M : N** (via `account_devices`) |
| transaction — flagged as — alert | 1 : 0..1 |
| account — has — baseline | 1 : 0..1 |
| category — classifies — merchant | 1 : N |
