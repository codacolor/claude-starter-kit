#!/usr/bin/env bash
#
# Bulk-add sources to a NotebookLM notebook with rate-limit guard, idempotency,
# and failure logging. Source-type-agnostic via --add-mode.
#
# Usage:
#   bulk_add.sh <notebook_id> <profile> <group_label> <manifest_tsv> \
#               <ledger_tsv> <failures_tsv> <add_mode>
#
# add_mode: youtube | url | drive | file | text
#
# Manifest TSV columns: <canonical_id>\t<title>\t<add_payload>
#   - youtube: canonical_id = video_id; payload = video_id (URL constructed here)
#   - url:     canonical_id = url; payload = url
#   - drive:   canonical_id = doc_id; payload = doc_id
#   - file:    canonical_id = abs_path; payload = abs_path
#   - text:    canonical_id = sha256(content); payload = abs_path of .txt file
#
# Ledger TSV columns: group\tsource_type\tcanonical_id\tsource_id\tadded_at\ttitle
# Failures TSV columns: group\tsource_type\tcanonical_id\tfailed_at\terror
#
# Source cap: warns at 250 sources, refuses past 290 unless
# NOTEBOOK_LM_FORCE_PAST_CAP=1 is set (NotebookLM Pro caps at ~300).
#
# Exits 0 even if some adds fail — caller checks failures.tsv. Exits non-zero
# only on argument or filesystem errors.
#
set -uo pipefail

NOTEBOOK_ID="${1:?notebook_id required}"
PROFILE="${2:?profile required}"
GROUP="${3:?group label required}"
MANIFEST="${4:?manifest TSV required}"
LEDGER="${5:?ledger TSV required}"
FAILURES="${6:?failures TSV required}"
ADD_MODE="${7:?add_mode required (youtube|url|drive|file|text)}"

case "$ADD_MODE" in
  youtube|url|drive|file|text) ;;
  *) echo "ERROR: invalid add_mode '$ADD_MODE' (expected youtube|url|drive|file|text)" >&2; exit 1 ;;
esac

[[ -f "$MANIFEST" ]] || { echo "ERROR: $MANIFEST not found" >&2; exit 1; }
touch "$LEDGER" "$FAILURES"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

ledger_count() {
  awk -F'\t' 'NR==1 && ($1=="group" || $1=="channel") {next} NF>0 {n++} END{print n+0}' "$LEDGER"
}

cur=$(ledger_count)
if [[ $cur -ge 290 && "${NOTEBOOK_LM_FORCE_PAST_CAP:-0}" != "1" ]]; then
  echo "ERROR: notebook has $cur sources (NotebookLM Pro cap is ~300)." >&2
  echo "       Set NOTEBOOK_LM_FORCE_PAST_CAP=1 to override." >&2
  exit 2
fi
if [[ $cur -ge 250 ]]; then
  echo "WARN: notebook has $cur sources, approaching the ~300 cap." >&2
fi

added=0
skipped=0
failed=0

while IFS=$'\t' read -r canonical_id title payload; do
  [[ -z "$canonical_id" ]] && continue
  [[ "$canonical_id" == "canonical_id" || "$canonical_id" == "video_id" ]] && continue

  # Idempotent: skip if canonical_id already in ledger column 3.
  if awk -F'\t' -v v="$canonical_id" '
       NR==1 && ($1=="group" || $1=="channel") {hdr=1; next}
       hdr && $3==v {found=1; exit}
       !hdr && $2==v {found=1; exit}
       END{exit !found}' "$LEDGER"; then
    skipped=$((skipped+1))
    continue
  fi

  case "$ADD_MODE" in
    youtube)
      url="https://www.youtube.com/watch?v=$payload"
      output=$(nlm source add "$NOTEBOOK_ID" --youtube "$url" --profile "$PROFILE" 2>&1) ;;
    url)
      output=$(nlm source add "$NOTEBOOK_ID" --url "$payload" --profile "$PROFILE" 2>&1) ;;
    drive)
      output=$(nlm source add "$NOTEBOOK_ID" --drive "$payload" --profile "$PROFILE" 2>&1) ;;
    file)
      output=$(nlm source add "$NOTEBOOK_ID" --file "$payload" --wait --profile "$PROFILE" 2>&1) ;;
    text)
      if [[ ! -f "$payload" ]]; then
        output="ERROR: text payload file not found: $payload"
      else
        content=$(cat "$payload")
        output=$(nlm source add "$NOTEBOOK_ID" --text "$content" --title "$title" --profile "$PROFILE" 2>&1)
      fi ;;
  esac

  if echo "$output" | grep -q "✓ Added source"; then
    source_id=$(echo "$output" | grep -oE "Source ID: [a-f0-9-]+" | awk '{print $3}')
    printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$GROUP" "$ADD_MODE" "$canonical_id" "$source_id" "$(ts)" "$title" >> "$LEDGER"
    added=$((added+1))
    echo "[+$added] $GROUP/$ADD_MODE: $title"
  else
    err=$(echo "$output" | tr '\n' ' ' | head -c 200)
    printf "%s\t%s\t%s\t%s\t%s\n" "$GROUP" "$ADD_MODE" "$canonical_id" "$(ts)" "$err" >> "$FAILURES"
    failed=$((failed+1))
    echo "[FAIL] $GROUP/$ADD_MODE: $title — $err"
  fi

  # Rate-limit guard: 1s between adds.
  sleep 1
done < "$MANIFEST"

echo
echo "===== $GROUP ($ADD_MODE): added=$added skipped=$skipped failed=$failed ====="
