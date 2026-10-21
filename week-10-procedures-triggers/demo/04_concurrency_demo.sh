#!/usr/bin/env bash
# Week 10 demo — ISOLATION: row locks make a second session WAIT.
#   Session A locks account 2 (SELECT ... FOR UPDATE) and holds it for 5 seconds.
#   Session B tries to update the same row and is blocked until A commits.
# Run from the repo root:   bash week-10-procedures-triggers/demo/04_concurrency_demo.sh
CONTAINER="${CONTAINER:-sentinel-db}"
PASS="${DB_ROOT_PASS:-sentinel_root_2026}"
m() { docker exec -i -e MYSQL_PWD="$PASS" "$CONTAINER" mysql -uroot -N sentinel "$@"; }

echo "A: START TRANSACTION; lock account 2; hold for 5 s ..."
m -e "START TRANSACTION; SELECT balance FROM accounts WHERE account_id = 2 FOR UPDATE; SELECT SLEEP(5); COMMIT;" >/dev/null 2>&1 &
sleep 1

echo "B: UPDATE the same row (this must wait for A) ..."
start=$(date +%s)
m -e "UPDATE accounts SET balance = balance + 1 WHERE account_id = 2;"
end=$(date +%s)
wait
echo "B was blocked for about $((end - start)) seconds (A held the lock for 5, started 1 second before B)."

m -e "UPDATE accounts SET balance = balance - 1 WHERE account_id = 2;"      # undo B's change
echo "balance restored."
