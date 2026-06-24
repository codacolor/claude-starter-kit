#!/usr/bin/env bash
#
# Remove sources from a NotebookLM notebook by canonical_id, source_id, or
# title substring. Updates the local ledger.
#
# Usage:
#   remove_source.sh <notebook_id> <profile> <ledger> --by-id <source_id>
#   remove_source.sh <notebook_id> <profile> <ledger> --by-canonical <canonical_id>
#   remove_source.sh <notebook_id> <profile> <ledger> --by-title <substring>
#
# For --by-title, if more than one ledger row matches, the script lists them
# and exits without deleting. Pass --confirm-multi to delete all matches.
#
set -uo pipefail

NOTEBOOK_ID="${1:?notebook_id required}"
PROFILE="${2:?profile required}"
LEDGER="${3:?ledger TSV required}"
MODE="${4:?--by-id | --by-canonical | --by-title required}"
QUERY="${5:?query value required}"
CONFIRM_MULTI="${6:-}"

[[ -f "$LEDGER" ]] || { echo "ERROR: $LEDGER not found" >&2; exit 1; }

# Detect ledger schema (legacy 5-col vs new 6-col) by header
hdr=$(head -1 "$LEDGER")
case "$hdr" in
  group*source_type*)  src_id_col=4; canonical_col=3; title_col=6 ;;
  channel*youtube_id*) src_id_col=3; canonical_col=2; title_col=5 ;;
  *) echo "ERROR: unrecognized ledger header: $hdr" >&2; exit 1 ;;
esac

case "$MODE" in
  --by-id)
    matches=$(awk -F'\t' -v c="$src_id_col" -v q="$QUERY" 'NR>1 && $c==q' "$LEDGER") ;;
  --by-canonical)
    matches=$(awk -F'\t' -v c="$canonical_col" -v q="$QUERY" 'NR>1 && $c==q' "$LEDGER") ;;
  --by-title)
    matches=$(awk -F'\t' -v c="$title_col" -v q="$QUERY" 'NR>1 && tolower($c) ~ tolower(q)' "$LEDGER") ;;
  *) echo "ERROR: invalid mode '$MODE'" >&2; exit 1 ;;
esac

if [[ -z "$matches" ]]; then
  echo "No matches in ledger for $MODE='$QUERY'" >&2
  exit 3
fi

count=$(echo "$matches" | grep -c .)
if [[ "$count" -gt 1 && "$CONFIRM_MULTI" != "--confirm-multi" ]]; then
  echo "Multiple matches ($count); pass --confirm-multi to delete all:" >&2
  echo "$matches" | awk -F'\t' -v c="$title_col" -v sc="$src_id_col" '{printf "  - %s (source_id=%s)\n", $c, $sc}' >&2
  exit 4
fi

removed=0
failed=0
while IFS=$'\t' read -r line; do
  [[ -z "$line" ]] && continue
  src_id=$(echo "$line" | awk -F'\t' -v c="$src_id_col" '{print $c}')
  title=$(echo "$line" | awk -F'\t' -v c="$title_col" '{print $c}')
  output=$(nlm source delete "$src_id" --confirm --profile "$PROFILE" 2>&1)
  if echo "$output" | grep -qiE "deleted|removed|✓"; then
    removed=$((removed+1))
    echo "[-] $title ($src_id)"
  else
    failed=$((failed+1))
    echo "[FAIL] $title ($src_id) — $output" >&2
  fi
done <<< "$matches"

# Rewrite ledger without the deleted source_ids
if [[ "$removed" -gt 0 ]]; then
  tmp=$(mktemp)
  removed_ids=$(echo "$matches" | awk -F'\t' -v c="$src_id_col" '{print $c}' | sort -u | tr '\n' '|' | sed 's/|$//')
  awk -F'\t' -v c="$src_id_col" -v rm="$removed_ids" '
    BEGIN {
      n = split(rm, arr, "|")
      for (i=1; i<=n; i++) ids[arr[i]] = 1
    }
    NR==1 { print; next }
    !($c in ids) { print }
  ' "$LEDGER" > "$tmp" && mv "$tmp" "$LEDGER"
fi

echo
echo "===== removed=$removed failed=$failed ====="
