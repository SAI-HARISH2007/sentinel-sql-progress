#!/usr/bin/env bash
# Shared helpers for build.sh / check.sh. Source it, do not run it.
#
# Two ways to reach MySQL:
#   docker mode (default): talks to the container started by `docker compose up -d`
#   host mode:             set DB_HOST (e.g. 127.0.0.1) to use a mysql client + server you already have
#
# Override anything with environment variables, e.g.
#   CONTAINER=wk-test DB_ROOT_PASS=t scripts/build.sh 5

CONTAINER="${CONTAINER:-sentinel-db}"
DB_ROOT_PASS="${DB_ROOT_PASS:-sentinel_root_2026}"
DB_NAME="${DB_NAME:-sentinel}"
DB_PORT="${DB_PORT:-3306}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# run_mysql [mysql args...]   — reads SQL from stdin
# --default-character-set=utf8mb4 matters: without it the mysql client may talk latin1 (it follows the OS locale),
# which breaks string comparisons against utf8mb4 columns and mangles characters such as the rupee sign.
run_mysql() {
  if [ -n "${DB_HOST:-}" ]; then
    MYSQL_PWD="$DB_ROOT_PASS" mysql -h "$DB_HOST" -P "$DB_PORT" -uroot --default-character-set=utf8mb4 "$@"
  else
    docker exec -i -e MYSQL_PWD="$DB_ROOT_PASS" "$CONTAINER" mysql -uroot --default-character-set=utf8mb4 "$@"
  fi
}

# week_dirs  — prints week directories in order
week_dirs() { ls -d "$ROOT_DIR"/week-[0-9][0-9]-* 2>/dev/null | sort; }

# week_num <dir>  — "week-07-joins" -> 7
week_num() { basename "$1" | sed -E 's/^week-0*([0-9]+)-.*/\1/'; }

# wait_for_mysql — blocks until the server accepts real (non-bootstrap) connections
wait_for_mysql() {
  local i
  for i in $(seq 1 60); do
    if echo "SELECT 1" | run_mysql -N >/dev/null 2>&1; then return 0; fi
    sleep 2
  done
  echo "MySQL did not become ready in 120 s" >&2
  return 1
}
