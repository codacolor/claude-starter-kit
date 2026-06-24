#!/usr/bin/env bash
#
# Adapter: local file → manifest. Copies each file into the per-notebook
# sources/ directory so the notebook folder stays self-contained, then emits
# a manifest pointing at the COPIED path (not the original).
#
# Output manifest TSV columns: <abs_copied_path>\t<title>\t<abs_copied_path>
#   (canonical_id = copied path, payload = copied path; bulk_add file mode
#    passes payload as --file)
#
# Usage: local_file.sh <notebook_folder> <output_manifest> <file_path> [<file_path> ...]
#   - notebook_folder: per-notebook Global Utility folder (sources/ created inside)
#   - output_manifest: where to write the manifest TSV
#   - file_path...: one or more source files to add (absolute or relative)
#
# Title is derived from the basename minus extension. Files with the same
# basename collide — script appends a numeric suffix to disambiguate.
#
set -uo pipefail

FOLDER="${1:?notebook folder required}"
OUTPUT="${2:?output manifest path required}"
shift 2
[[ $# -ge 1 ]] || { echo "ERROR: at least one file path required" >&2; exit 1; }

SOURCES_DIR="$FOLDER/sources"
mkdir -p "$SOURCES_DIR"

: > "$OUTPUT"  # truncate

for src in "$@"; do
  if [[ ! -f "$src" ]]; then
    echo "WARN: skipping (not a file): $src" >&2
    continue
  fi

  src_abs="$(cd "$(dirname "$src")" && pwd)/$(basename "$src")"
  base="$(basename "$src")"
  dest="$SOURCES_DIR/$base"

  # Disambiguate collisions by appending -2, -3, etc.
  if [[ -e "$dest" && ! "$src_abs" -ef "$dest" ]]; then
    stem="${base%.*}"
    ext="${base##*.}"
    [[ "$stem" == "$base" ]] && ext=""  # no extension
    n=2
    while [[ -e "$SOURCES_DIR/${stem}-${n}${ext:+.$ext}" ]]; do n=$((n+1)); done
    dest="$SOURCES_DIR/${stem}-${n}${ext:+.$ext}"
  fi

  # Copy (skip if same inode = already copied)
  if [[ ! "$src_abs" -ef "$dest" ]]; then
    cp "$src_abs" "$dest"
  fi

  title="$(basename "$dest")"
  title="${title%.*}"  # strip extension for display
  printf "%s\t%s\t%s\n" "$dest" "$title" "$dest" >> "$OUTPUT"
  echo "STAGED: $dest" >&2
done

ROWS=$(wc -l < "$OUTPUT" | tr -d ' ')
echo "MANIFEST: $ROWS files -> $OUTPUT" >&2
