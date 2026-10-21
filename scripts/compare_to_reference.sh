#!/usr/bin/env bash
# compare_to_reference.sh — diff the current schema against the frozen reference in
# reference/schema_fingerprint_week10.txt (the schema of the original one-shot `sentinel-sql` project,
# plus the intentional changes listed in CHANGES_FROM_ORIGINAL.md).
#
#   scripts/compare_to_reference.sh           # compare
#   scripts/compare_to_reference.sh --update  # overwrite the reference (only after a deliberate schema change)
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

REF="$ROOT_DIR/reference/schema_fingerprint_week10.txt"
NOW="$(mktemp)"
run_mysql -N < "$ROOT_DIR/scripts/fingerprint.sql" > "$NOW"

if [ "${1:-}" = "--update" ]; then
  mkdir -p "$(dirname "$REF")"; cp "$NOW" "$REF"; echo "reference updated: $REF"; exit 0
fi
if diff -u "$REF" "$NOW"; then echo "schema matches reference"; else echo "SCHEMA DIFFERS FROM REFERENCE"; exit 1; fi
