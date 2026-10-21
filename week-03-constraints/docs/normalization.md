> **Where this fits:** normalisation is lectures 23–25 of the theory course, but the *outcome* of it is the keys and
> constraints you added this week, so the argument lives next to them. Read it after you have attended those lectures.
> For the end-semester exam, the same method (find the functional dependencies, check each normal form in turn)
> is what a Part C question asks you to do on a given relation.

# Normalization — 3NF Argument

## Overview

Every table in the Sentinel schema is analyzed below for normalization from 1NF through 3NF (and BCNF where applicable). The goal: no partial dependencies, no transitive dependencies, and every non-key attribute depends on the whole key, nothing but the key, so help me Codd.

---

## Table-by-Table Analysis

### 1. `users`

| Attribute | Depends On |
|-----------|-----------|
| full_name | user_id |
| email | user_id |
| phone | user_id |
| date_of_birth | user_id |
| created_at | user_id (auto) |

- **1NF:** All attributes are atomic. No repeating groups.
- **2NF:** Single-column PK (user_id), so no partial dependencies possible.
- **3NF:** No transitive dependencies. `email` is unique but determined by `user_id`, not by another non-key attribute.
- **BCNF:** Every determinant is a candidate key. ✓

### 2. `accounts`

| Attribute | Depends On |
|-----------|-----------|
| user_id | account_id |
| account_type | account_id |
| balance | account_id |
| status | account_id |

- **1NF:** Atomic values. ✓
- **2NF:** Single-column PK. ✓
- **3NF:** `user_id` is a FK but directly describes the account (which user owns it). No transitive dependency — balance does not depend on user_id, it depends on account_id.
- **BCNF:** ✓

### 3. `locations`

| Attribute | Depends On |
|-----------|-----------|
| city | location_id |
| state | location_id |
| country | location_id |
| latitude | location_id |
| longitude | location_id |

- **1NF:** Atomic. ✓
- **2NF:** Single-column PK. ✓
- **3NF:** `latitude` and `longitude` are determined by `location_id` (not transitively by city — a city can have multiple points). `UNIQUE(city, country)` is an alternate key, not a transitive dependency.
- **BCNF:** ✓

### 4. `devices`

| Attribute | Depends On |
|-----------|-----------|
| device_type | device_id |
| os | device_id |
| browser | device_id |
| fingerprint_hash | device_id |

- **1NF:** Atomic. ✓
- **2NF:** Single-column PK. ✓
- **3NF:** No transitive dependencies.
- **BCNF:** `fingerprint_hash` is a candidate key (UNIQUE). The only determinant is device_id and fingerprint_hash, both keys. ✓

### 5. `merchants`

| Attribute | Depends On |
|-----------|-----------|
| merchant_name | merchant_id |
| category_id | merchant_id |
| city | merchant_id |
| latitude | merchant_id |
| longitude | merchant_id |
| risk_score | merchant_id |

- **1NF:** Atomic. ✓
- **2NF:** Single-column PK. ✓
- **3NF:** `category_id` is a FK that directly describes the merchant. `city`, `latitude`, `longitude` describe where the merchant is located — they depend on merchant_id, not transitively through category_id.
- **BCNF:** ✓

### 6. `merchant_categories`

- Simple lookup table. 3NF and BCNF by inspection. ✓

### 7. `rule_config`

- Simple key-value configuration. 3NF and BCNF by inspection. ✓

### 8. `account_devices` (composite PK)

| Attribute | Depends On |
|-----------|-----------|
| first_seen | (account_id, device_id) |
| last_seen | (account_id, device_id) |

- **1NF:** Atomic. ✓
- **2NF:** Composite PK — but `first_seen` and `last_seen` depend on the *whole* key, not just one column. A device's first_seen for an account depends on *both* the account and the device.
- **3NF:** No transitive dependencies. ✓
- **BCNF:** ✓

### 9. `transactions`

| Attribute | Depends On |
|-----------|-----------|
| account_id | txn_id |
| merchant_id | txn_id |
| device_id | txn_id |
| location_id | txn_id |
| amount | txn_id |
| txn_time | txn_id |
| status | txn_id |
| metadata_json | txn_id |

- **1NF:** Atomic. `metadata_json` stores variable attributes (JSON column is MySQL's approach to semi-structured data; the core transactional fields are all atomic columns).
- **2NF:** Single-column PK. ✓
- **3NF:** All FKs and attributes depend directly on txn_id. No transitive dependencies — `amount` does not depend on `merchant_id` within this table (merchant risk is computed externally).
- **BCNF:** ✓

### 10. `alerts`

| Attribute | Depends On |
|-----------|-----------|
| txn_id | alert_id |
| rule_name | alert_id |
| risk_score | alert_id |
| reasons | alert_id |
| status | alert_id |

- **1NF:** Atomic (reasons is JSON for variable-length rule details). ✓
- **2NF:** Single-column PK. `txn_id` is UNIQUE (1:1 with transactions). ✓
- **3NF:** No transitive dependencies.
- **BCNF:** ✓

### 11. `behaviour_baselines`

| Attribute | Depends On |
|-----------|-----------|
| account_id | baseline_id |
| avg_amount | baseline_id |
| stddev_amount | baseline_id |
| peak_hours_json | baseline_id |
| typical_cities_json | baseline_id |

- **1NF:** JSON columns store computed distributions (peaks hours as JSON array, cities as JSON array). Core statistical fields are atomic.
- **2NF:** Single-column PK. ✓
- **3NF:** `account_id` is UNIQUE (1:1 with accounts). All attributes depend on baseline_id. No transitive dependencies.
- **BCNF:** ✓

### 12. `login_history`

- Composite of FKs + timestamp + boolean. All depend on the PK (login_id). 3NF and BCNF. ✓

### 13. `audit_log`

- Log table. All attributes describe the audit event. No transitive dependencies. 3NF and BCNF. ✓

---

## Summary

All 13 tables are in **3NF** (and BCNF). The schema avoids:
- **Partial dependencies** by using single-column PKs everywhere except `account_devices`, where the composite key is necessary and all non-key attributes depend on the full composite.
- **Transitive dependencies** by placing lookup data (`merchant_categories`, `locations`) in separate tables rather than embedding city/category names in fact tables.
- **Multi-valued attributes** by using junction tables (`account_devices`) and JSON columns only for genuinely variable/computed data (reasons, peak hours, metadata).
