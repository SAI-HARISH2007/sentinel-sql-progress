-- Week 7 — FRAUD RULE 3: new device.  LEFT JOIN … IS NULL, the anti-join pattern.
-- account_devices lists every (account, device) pair that is known to be legitimate.
-- A transaction whose pair is NOT in that list came from a device this account has never used.
USE sentinel;

SELECT t.txn_id, t.account_id, t.device_id, d.fingerprint_hash, t.amount
FROM transactions t
JOIN devices d                ON d.device_id = t.device_id
LEFT JOIN account_devices ad  ON ad.account_id = t.account_id AND ad.device_id = t.device_id
WHERE ad.account_id IS NULL                -- no matching known pair  =>  new device
  AND t.txn_id >= 12041                    -- (restricted to the persona rows to keep the output short)
ORDER BY t.txn_id;
-- Expected: txn 12052 (device 999) plus most of the "bad merchant" transactions 12053-12067, whose
-- device the generator picked at random, i.e. usually one this account never used.

-- How common is it over the whole history?
SELECT COUNT(*) AS txns_on_unknown_devices
FROM transactions t
LEFT JOIN account_devices ad ON ad.account_id = t.account_id AND ad.device_id = t.device_id
WHERE ad.account_id IS NULL;
