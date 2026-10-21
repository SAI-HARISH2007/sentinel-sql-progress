#!/usr/bin/env bash
# build.sh N — rebuild the `sentinel` database exactly as it stood at the END of week N.
#
#   scripts/build.sh 3     # weeks 1-3: empty tables with all constraints, no data yet
#   scripts/build.sh 10    # everything: data, views, indexes, roles, procedures, triggers
#
# What it does: for each week 1..N, in order, runs every file in that week's sql/ folder
# (sorted by filename). Files in queries/, demo/ and lab-practice/ are NOT loaded — those are
# run by hand (see each week's README) and are exercised by scripts/check.sh instead.
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

N="${1:?usage: scripts/build.sh <week 1-11>}"
wait_for_mysql

for dir in $(week_dirs); do
  w=$(week_num "$dir")
  [ "$w" -le "$N" ] || continue
  if [ -d "$dir/sql" ]; then
    for f in $(ls "$dir"/sql/*.sql 2>/dev/null | sort); do
      printf '  week %02d  %s\n' "$w" "$(basename "$f")"
      run_mysql < "$f"
    done
  fi
done
echo "==> sentinel is now at the end of week $N"
