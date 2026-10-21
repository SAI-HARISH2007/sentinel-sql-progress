#!/usr/bin/env bash
# Week 9 demo — least privilege, seen from three different logins. Run from the repo root:
#     bash week-09-views-indexes-dcl/demo/dcl_demo.sh
# (Docker mode. Set CONTAINER / DB_ROOT_PASS if yours differ from the defaults.)
CONTAINER="${CONTAINER:-sentinel-db}"
ROOT_PASS="${DB_ROOT_PASS:-sentinel_root_2026}"

as() {  # as <user> <password> <sql>
  docker exec -i -e MYSQL_PWD="$2" "$CONTAINER" mysql -u"$1" sentinel -e "$3" 2>&1 | sed 's/^/    /'
}

echo "== 1. analyst_user (role fraud_analyst) reads a VIEW ................ allowed"
as analyst_user analyst_2026 "SELECT txn_date, total_txns, total_amount FROM v_daily_txn_summary LIMIT 3;"

echo "== 2. analyst_user reads the RAW TABLE ............................... denied (ERROR 1142)"
as analyst_user analyst_2026 "SELECT COUNT(*) FROM transactions;"

echo "== 3. analyst_user tries to DELETE a transaction ..................... denied"
as analyst_user analyst_2026 "DELETE FROM transactions WHERE txn_id = 1;"

echo "== 4. app_user (role txn_app) reads transactions ..................... allowed"
as app_user app_2026 "SELECT COUNT(*) AS txns FROM transactions;"

echo "== 5. app_user reads personal data in users .......................... denied"
as app_user app_2026 "SELECT email FROM users LIMIT 1;"

echo "== 6. REVOKE in action: take the view away from the role, retry, give it back"
docker exec -i -e MYSQL_PWD="$ROOT_PASS" "$CONTAINER" mysql -uroot -e "REVOKE SELECT ON sentinel.v_daily_txn_summary FROM 'fraud_analyst';"
echo "   (revoked)"
as analyst_user analyst_2026 "SELECT COUNT(*) FROM v_daily_txn_summary;"
docker exec -i -e MYSQL_PWD="$ROOT_PASS" "$CONTAINER" mysql -uroot -e "GRANT SELECT ON sentinel.v_daily_txn_summary TO 'fraud_analyst';"
echo "   (granted again)"
as analyst_user analyst_2026 "SELECT COUNT(*) AS days FROM v_daily_txn_summary;"

echo "== 7. What each account may do"
docker exec -i -e MYSQL_PWD="$ROOT_PASS" "$CONTAINER" mysql -uroot -e "SHOW GRANTS FOR 'analyst_user'@'%' USING 'fraud_analyst';" 2>&1 | grep -v 'Using a password' | sed 's/^/    /' | cut -c1-160
