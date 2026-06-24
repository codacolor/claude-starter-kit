#!/usr/bin/env bash
#
# Adapter: pasted text → manifest. Writes each text snippet to a .txt file
# under the per-notebook texts/ directory and emits a manifest pointing at
# that file. bulk_add text mode reads the file and passes content via
# --text "..." to nlm source add.
#
# Output manifest TSV columns: <sha256>\t<title>\t<abs_text_path>
#   (canonical_id = sha256 of "title|content", payload = .txt file path)
#
# Usage:
#   # Single snippet via args:
#   text.sh <notebook_folder> <output_manifest> <title> <content>
#
#   # Multiple snippets via JSON (one per line, format: {"title":"...", "content":"..."}):
#   text.sh <notebook_folder> <output_manifest> --from-jsonl <jsonl_path>
#
set -uo pipefail

FOLDER="${1:?notebook folder required}"
OUTPUT="${2:?output manifest path required}"
shift 2

TEXTS_DIR="$FOLDER/texts"
mkdir -p "$TEXTS_DIR"

: > "$OUTPUT"

emit_one() {
  local title="$1"
  local content="$2"
  if [[ -z "$title" || -z "$content" ]]; then
    echo "WARN: skipping empty title or content" >&2
    return
  fi
  # Hash for dedup / canonical_id
  local hash
  hash=$(printf "%s|%s" "$title" "$content" | shasum -a 256 | awk '{print $1}')
  # Sanitize title for filename
  local safe_title
  safe_title=$(echo "$title" | tr -c 'A-Za-z0-9._-' '_' | head -c 60)
  local dest="$TEXTS_DIR/${safe_title}_${hash:0:8}.txt"
  printf "%s" "$content" > "$dest"
  printf "%s\t%s\t%s\n" "$hash" "$title" "$dest" >> "$OUTPUT"
  echo "STAGED: $dest ($hash)" >&2
}

if [[ "${1:-}" == "--from-jsonl" ]]; then
  JSONL="${2:?jsonl path required}"
  [[ -f "$JSONL" ]] || { echo "ERROR: $JSONL not found" >&2; exit 1; }
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    title=$(echo "$line" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read()).get("title",""))')
    content=$(echo "$line" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read()).get("content",""))')
    emit_one "$title" "$content"
  done < "$JSONL"
else
  TITLE="${1:?title required}"
  CONTENT="${2:?content required}"
  emit_one "$TITLE" "$CONTENT"
fi

ROWS=$(wc -l < "$OUTPUT" | tr -d ' ')
echo "MANIFEST: $ROWS text snippets -> $OUTPUT" >&2
