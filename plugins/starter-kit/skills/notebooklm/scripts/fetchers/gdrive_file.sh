#!/usr/bin/env bash
#
# Adapter: Google Drive file → manifest. Extracts the doc-id from a Drive URL
# (or accepts a raw doc-id) and emits a manifest. NotebookLM ingests Drive
# docs by ID — no Drive API auth needed for this adapter (it just normalizes
# the input).
#
# Output manifest TSV columns: <doc_id>\t<title>\t<doc_id>
#   (canonical_id = doc_id, payload = doc_id; bulk_add drive mode passes
#    payload as --drive)
#
# Usage: gdrive_file.sh <output_manifest> <url_or_id> [<url_or_id> ...]
#
# Title defaults to "Drive doc <doc_id_short>". For accurate Drive titles you'd
# need the Drive API — deferred. NotebookLM may surface a better title on ingest.
#
set -uo pipefail

OUTPUT="${1:?output manifest path required}"
shift
[[ $# -ge 1 ]] || { echo "ERROR: at least one Drive URL or ID required" >&2; exit 1; }

: > "$OUTPUT"

extract_id() {
  local input="$1"
  # Strip query string if any
  input="${input%%\?*}"
  case "$input" in
    https://docs.google.com/*/d/*)
      # e.g. https://docs.google.com/document/d/ABC123/edit
      echo "$input" | sed -E 's|.*/d/([^/]+).*|\1|'
      ;;
    https://drive.google.com/file/d/*)
      echo "$input" | sed -E 's|.*/file/d/([^/]+).*|\1|'
      ;;
    https://drive.google.com/open*id=*)
      echo "$input" | sed -E 's|.*[?&]id=([^&]+).*|\1|'
      ;;
    https://*)
      echo "WARN: unrecognized Drive URL pattern: $input" >&2
      echo ""
      ;;
    *)
      # Assume raw ID
      echo "$input"
      ;;
  esac
}

# Dedupe (preserve first-seen order). Bash 3.2 on macOS lacks associative
# arrays, so use a delimited string for membership checks.
seen=$'\n'
for input in "$@"; do
  doc_id=$(extract_id "$input")
  if [[ -z "$doc_id" ]]; then
    continue
  fi
  if [[ "$seen" == *$'\n'"$doc_id"$'\n'* ]]; then
    echo "WARN: duplicate Drive ID skipped: $doc_id" >&2
    continue
  fi
  seen+="$doc_id"$'\n'
  title="Drive doc ${doc_id:0:8}"
  printf "%s\t%s\t%s\n" "$doc_id" "$title" "$doc_id" >> "$OUTPUT"
  echo "STAGED: $doc_id" >&2
done

ROWS=$(wc -l < "$OUTPUT" | tr -d ' ')
echo "MANIFEST: $ROWS Drive docs -> $OUTPUT" >&2
