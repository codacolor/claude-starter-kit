#!/usr/bin/env bash
#
# Adapter: web URL → manifest. Dedupes input URLs and writes a manifest.
# Title is the URL itself (NotebookLM will replace it with the page title on
# ingest). For more accurate titles, fetch the <title> tag — currently skipped
# to keep this adapter dependency-free and fast.
#
# Output manifest TSV columns: <url>\t<title>\t<url>
#   (canonical_id = url, payload = url; bulk_add url mode passes payload as --url)
#
# Usage: url.sh <output_manifest> <url> [<url> ...]
#   OR:   url.sh <output_manifest> --from-stdin   (reads one URL per line)
#
set -uo pipefail

OUTPUT="${1:?output manifest path required}"
shift
[[ $# -ge 1 ]] || { echo "ERROR: at least one URL or --from-stdin required" >&2; exit 1; }

# Collect URLs into an array
urls=()
if [[ "$1" == "--from-stdin" ]]; then
  while IFS= read -r line; do
    line="${line## }"; line="${line%% }"  # trim
    [[ -z "$line" || "$line" == \#* ]] && continue
    urls+=("$line")
  done
else
  urls=("$@")
fi

# Dedupe (preserve first-seen order). Bash 3.2 on macOS lacks associative
# arrays, so use a delimited string for membership checks.
seen=$'\n'
: > "$OUTPUT"
for u in "${urls[@]}"; do
  # Light validation: must look like http(s)://
  if [[ ! "$u" =~ ^https?:// ]]; then
    echo "WARN: skipping (not http/https): $u" >&2
    continue
  fi
  if [[ "$seen" == *$'\n'"$u"$'\n'* ]]; then
    echo "WARN: duplicate skipped: $u" >&2
    continue
  fi
  seen+="$u"$'\n'
  printf "%s\t%s\t%s\n" "$u" "$u" "$u" >> "$OUTPUT"
done

ROWS=$(wc -l < "$OUTPUT" | tr -d ' ')
echo "MANIFEST: $ROWS URLs -> $OUTPUT" >&2
