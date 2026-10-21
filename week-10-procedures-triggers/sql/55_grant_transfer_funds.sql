-- =============================================================================
-- Week 10 — DCL for the new procedure
-- 55_grant_transfer_funds.sql
-- =============================================================================
-- The txn_app role was created in Week 9, before transfer_funds existed, so this routine-level grant lives here.
-- transfer_funds runs with its definer's rights (SQL SECURITY DEFINER, the default), so the application can move money
-- through the procedure without any direct UPDATE right on accounts.

USE sentinel;

GRANT EXECUTE ON PROCEDURE sentinel.transfer_funds TO 'txn_app';
