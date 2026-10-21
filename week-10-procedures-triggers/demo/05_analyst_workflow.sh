#!/usr/bin/env bash
# Week 10 demo — the whole system from three different logins (needs Week 9's roles):
#   app_user      can only INSERT transactions ......... yet the fraud check still runs (triggers use the DEFINER's rights)
#   analyst_user  can read alert views and close alerts, but cannot touch transactions or delete alerts
#   root          reads the audit trail and cleans up
# Run from the repo root:   bash week-10-procedures-triggers/demo/05_analyst_workflow.sh
CONTAINER="${CONTAINER:-sentinel-db}"
ROOT_PASS="${DB_ROOT_PASS:-sentinel_root_2026}"
as()  { docker exec -i -e MYSQL_PWD="$2" "$CONTAINER" mysql -u"$1" -t sentinel -e "$3" 2>&1 | grep -v 'Using a password' | sed 's/^/    /'; }
asn() { docker exec -i -e MYSQL_PWD="$2" "$CONTAINER" mysql -u"$1" -N sentinel -e "$3" 2>&1 | grep -v 'Using a password'; }

echo "== 1. app_user inserts a suspicious payment (its only privilege)"
as app_user app_2026 "INSERT INTO transactions (account_id, merchant_id, device_id, location_id, amount, txn_time) VALUES (1, 1, 999, 4, 95000.00, '2026-09-02 03:15:00');"

echo "== 2. app_user cannot read the alerts that its own insert caused ..."
as app_user app_2026 "SELECT COUNT(*) FROM alerts;"
echo "   ... but analyst_user can see them through the view:"
as analyst_user analyst_2026 "SELECT alert_id, txn_id, risk_score, reasons FROM v_active_alerts WHERE amount = 95000 AND txn_time = '2026-09-02 03:15:00';"
ALERT_ID=$(asn analyst_user analyst_2026 "SELECT alert_id FROM v_active_alerts WHERE amount = 95000 AND txn_time = '2026-09-02 03:15:00' LIMIT 1;")

echo "== 3. analyst_user reads raw transactions (denied), then closes alert $ALERT_ID (allowed)"
as analyst_user analyst_2026 "SELECT COUNT(*) FROM transactions;"
as analyst_user analyst_2026 "UPDATE alerts SET status = 'false_positive' WHERE alert_id = $ALERT_ID;"

echo "== 4. analyst_user may not delete the evidence"
as analyst_user analyst_2026 "DELETE FROM alerts WHERE alert_id = $ALERT_ID;"

echo "== 5. root reads the result: review time stamped by the BEFORE trigger, and WHO closed it recorded by the AFTER trigger"
docker exec -i -e MYSQL_PWD="$ROOT_PASS" "$CONTAINER" mysql -uroot -t sentinel -e "
  SELECT alert_id, status, reviewed_at IS NOT NULL AS reviewed_at_stamped FROM alerts WHERE alert_id = $ALERT_ID;
  SELECT record_id, old_value_json, new_value_json, changed_by FROM audit_log WHERE table_name = 'alerts' AND record_id = $ALERT_ID;" 2>&1 | grep -v 'Using a password' | sed 's/^/    /'

echo "== 6. clean up"
docker exec -i -e MYSQL_PWD="$ROOT_PASS" "$CONTAINER" mysql -uroot sentinel -e "
  DELETE FROM audit_log WHERE table_name = 'alerts' AND record_id = $ALERT_ID;
  DELETE FROM transactions WHERE amount = 95000.00 AND txn_time = '2026-09-02 03:15:00';
  SELECT COUNT(*) AS alerts_left FROM alerts;" 2>&1 | grep -v 'Using a password' | sed 's/^/    /'
