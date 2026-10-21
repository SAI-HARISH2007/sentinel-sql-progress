#!/usr/bin/env bash
# check.sh N — verify the database is correct for week N.
#
#   scripts/check.sh 7
#
# Runs, for every week 1..N:
#   * check.sql          every row must say PASS (any FAIL fails the script)
#   * queries/*.sql      must run without error
#   * demo/*.sql         must run without error (demos clean up after themselves);
#                        files named *violation* are SUPPOSED to raise errors and are run with --force
#
# Run scripts/build.sh N first. Exit code 0 = all good.
set -uo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

N="${1:?usage: scripts/check.sh <week 1-11>}"
fail=0
pass=0

for dir in $(week_dirs); do
  w=$(week_num "$dir")
  [ "$w" -le "$N" ] || continue

  if [ -f "$dir/check.sql" ]; then
    out=$(run_mysql -N "$DB_NAME" < "$dir/check.sql" 2>&1)
    rc=$?
    if [ $rc -ne 0 ] || echo "$out" | grep -q 'FAIL'; then
      printf 'FAIL  week %02d  check.sql\n' "$w"; echo "$out" | grep -E 'FAIL|ERROR' | sed 's/^/        /'; fail=$((fail+1))
    else
      printf 'ok    week %02d  check.sql (%s assertions)\n' "$w" "$(echo "$out" | grep -c PASS)"; pass=$((pass+1))
    fi
  fi

  for f in $(ls "$dir"/queries/*.sql "$dir"/demo/*.sql 2>/dev/null | sort); do
    # lab-practice and other self-contained scripts manage their own database
    case "$f" in
      *violation*)
        out=$(run_mysql --force "$DB_NAME" < "$f" 2>&1 | grep -c '^ERROR') ;;
      *)
        out=$(run_mysql "$DB_NAME" < "$f" 2>&1 >/dev/null | grep -c '^ERROR') ;;
    esac
    case "$f" in
      *violation*) want=$(grep -c -- '-- EXPECT ERROR' "$f")
                   if [ "$out" -eq "$want" ] && [ "$want" -gt 0 ]; then ok=1; else ok=0; echo "      $f: expected $want errors, got $out"; fi ;;
      *)           if [ "$out" -eq 0 ]; then ok=1; else ok=0; fi ;;
    esac
    if [ $ok -eq 1 ]; then pass=$((pass+1)); else
      printf 'FAIL  week %02d  %s\n' "$w" "${f#"$ROOT_DIR"/}"; fail=$((fail+1))
    fi
  done

  # lab-practice scripts create and drop their own database `lab_practice`
  for f in $(ls "$dir"/lab-practice/*.sql 2>/dev/null | sort); do
    if run_mysql < "$f" >/dev/null 2>&1; then pass=$((pass+1)); else
      printf 'FAIL  week %02d  %s\n' "$w" "${f#"$ROOT_DIR"/}"; fail=$((fail+1))
    fi
  done
done

echo "----"
echo "passed: $pass   failed: $fail"
[ $fail -eq 0 ]
