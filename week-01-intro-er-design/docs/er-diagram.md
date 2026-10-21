# ER diagram — Sentinel

> **Generated** by `scripts/gen_er_docs.py` from the real schema (`reference/schema_fingerprint_week10.txt`). Do not edit by hand;
> change the schema, rebuild, run `scripts/compare_to_reference.sh --update`, then `python3 scripts/gen_er_docs.py`.
> Reading the diagram: `||` exactly one, `o|` zero or one, `o{` zero or many. `PK` primary key, `FK` foreign key, `UK` unique key.
> In the lab you will *draw* this in the notation your faculty uses (rectangles, ellipses, diamonds - see `materials/src/NOTES/Key_features of ER.jpeg`
> in your DBMS study folder). This is the same content in a machine-drawn form. For the exam notation, translate it by hand.

```mermaid
erDiagram
    accounts ||--o{ account_devices : "uses"
    devices ||--o{ account_devices : "known on"
    users ||--o{ accounts : "owns"
    transactions ||--o| alerts : "flagged as"
    accounts ||--o| behaviour_baselines : "has baseline"
    accounts ||--o{ login_history : "logs in"
    devices ||--o{ login_history : "used for"
    locations ||--o{ login_history : "from"
    merchant_categories ||--o{ merchants : "classifies"
    accounts ||--o{ transactions : "makes"
    devices ||--o{ transactions : "used in"
    locations ||--o{ transactions : "happens at"
    merchants ||--o{ transactions : "receives"

    account_devices {
        int account_id PK,FK
        int device_id PK,FK
        timestamp first_seen  "optional"
        timestamp last_seen  "optional"
    }
    accounts {
        int account_id PK
        int user_id FK
        enum account_type
        decimal balance
        enum status
        timestamp created_at  "optional"
    }
    alerts {
        bigint alert_id PK
        bigint txn_id FK,UK
        varchar rule_name
        decimal risk_score
        json reasons  "optional"
        enum status
        timestamp created_at  "optional"
        timestamp reviewed_at  "optional"
    }
    audit_log {
        bigint audit_id PK
        varchar table_name
        bigint record_id
        enum action
        json old_value_json  "optional"
        json new_value_json  "optional"
        varchar changed_by  "optional"
        timestamp changed_at  "optional"
    }
    behaviour_baselines {
        int baseline_id PK
        int account_id FK,UK
        decimal avg_amount  "optional"
        decimal stddev_amount  "optional"
        json peak_hours_json  "optional"
        json typical_cities_json  "optional"
        timestamp updated_at  "optional"
    }
    devices {
        int device_id PK
        enum device_type
        varchar os  "optional"
        varchar browser  "optional"
        varchar fingerprint_hash UK
    }
    locations {
        int location_id PK
        varchar city
        varchar state  "optional"
        varchar country
        decimal latitude
        decimal longitude
    }
    login_history {
        bigint login_id PK
        int account_id FK
        int device_id FK
        int location_id FK
        timestamp login_time  "optional"
        tinyint success
    }
    merchant_categories {
        int category_id PK
        varchar category_name UK
        text description  "optional"
    }
    merchants {
        int merchant_id PK
        varchar merchant_name
        int category_id FK
        varchar city
        decimal latitude
        decimal longitude
        decimal risk_score  "optional"
    }
    rule_config {
        int rule_id PK
        varchar rule_name UK
        tinyint enabled
        decimal threshold_value
        json parameters_json  "optional"
        timestamp updated_at  "optional"
    }
    transactions {
        bigint txn_id PK
        int account_id FK
        int merchant_id FK
        int device_id FK
        int location_id FK
        decimal amount
        timestamp txn_time
        enum status
        json metadata_json  "optional"
    }
    users {
        int user_id PK
        varchar full_name
        varchar email UK
        varchar phone  "optional"
        date date_of_birth  "optional"
        timestamp created_at  "optional"
    }
```

## The 13 entities

| Table | Primary key | Columns | Foreign keys |
|---|---|---|---|
| `account_devices` | `account_id`, `device_id` | 4 | `account_id` → `accounts`, `device_id` → `devices` |
| `accounts` | `account_id` | 6 | `user_id` → `users` |
| `alerts` | `alert_id` | 8 | `txn_id` → `transactions` |
| `audit_log` | `audit_id` | 8 | — |
| `behaviour_baselines` | `baseline_id` | 7 | `account_id` → `accounts` |
| `devices` | `device_id` | 5 | — |
| `locations` | `location_id` | 6 | — |
| `login_history` | `login_id` | 6 | `account_id` → `accounts`, `device_id` → `devices`, `location_id` → `locations` |
| `merchant_categories` | `category_id` | 3 | — |
| `merchants` | `merchant_id` | 7 | `category_id` → `merchant_categories` |
| `rule_config` | `rule_id` | 6 | — |
| `transactions` | `txn_id` | 9 | `account_id` → `accounts`, `device_id` → `devices`, `location_id` → `locations`, `merchant_id` → `merchants` |
| `users` | `user_id` | 6 | — |

## Foreign keys and their delete rules

| Foreign key | Parent → child | ON DELETE |
|---|---|---|
| `fk_ad_account` | `accounts.account_id` ← `account_devices.account_id` | CASCADE |
| `fk_ad_device` | `devices.device_id` ← `account_devices.device_id` | CASCADE |
| `fk_accounts_user` | `users.user_id` ← `accounts.user_id` | CASCADE |
| `fk_alert_txn` | `transactions.txn_id` ← `alerts.txn_id` | CASCADE |
| `fk_bb_account` | `accounts.account_id` ← `behaviour_baselines.account_id` | CASCADE |
| `fk_lh_account` | `accounts.account_id` ← `login_history.account_id` | CASCADE |
| `fk_lh_device` | `devices.device_id` ← `login_history.device_id` | RESTRICT |
| `fk_lh_location` | `locations.location_id` ← `login_history.location_id` | RESTRICT |
| `fk_merchants_category` | `merchant_categories.category_id` ← `merchants.category_id` | RESTRICT |
| `fk_txn_account` | `accounts.account_id` ← `transactions.account_id` | CASCADE |
| `fk_txn_device` | `devices.device_id` ← `transactions.device_id` | RESTRICT |
| `fk_txn_location` | `locations.location_id` ← `transactions.location_id` | RESTRICT |
| `fk_txn_merchant` | `merchants.merchant_id` ← `transactions.merchant_id` | RESTRICT |

`CASCADE` = deleting the parent deletes the children. `RESTRICT` = the parent cannot be deleted while children exist.
How each rule turned into a table is explained in [`er-to-relational.md`](er-to-relational.md).
