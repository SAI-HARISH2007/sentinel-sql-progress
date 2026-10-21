-- =============================================================================
-- Week 10 — back-fill the alerts for the five planted fraud personas
-- 60_backfill_personas.sql
-- =============================================================================
-- The 12,067 transactions were loaded in Week 4, BEFORE the trigger existed, so none of them was scored.
-- Transactions 12041-12067 are the fraud personas (see week-04-dml/seed/generate.py). Score them now.
-- Only the personas are back-filled on purpose, so the alerts table tells a clean story for the demo.
-- Back-filling ALL 12,067 transactions is possible (CALL backfill_alerts(1, 12067); measured: 38 seconds) and creates
-- 634 alerts, because the random background data trips rules like "new device" now and then. The trigger covers
-- everything inserted from now on.
-- Order matters for Rule 6 (merchant risk reads the alerts that already exist), so the range is scored in id order.

USE sentinel;
CALL backfill_alerts(12041, 12067);
