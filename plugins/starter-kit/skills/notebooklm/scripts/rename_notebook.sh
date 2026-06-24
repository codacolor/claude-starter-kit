#!/usr/bin/env bash
#
# Rename a notebook on NotebookLM AND rename the corresponding local folder
# to keep them in sync.
#
# Usage: rename_notebook.sh <notebook_id> <new_title> <profile> <old_folder>
#   - notebook_id: the UUID
#   - new_title: the new notebook title
#   - profile: nlm profile
#   - old_folder: current absolute path of the local per-notebook folder
#
# Behavior:
#   1. Calls `nlm notebook rename <id> "<new_title>"` first. Aborts if it fails.
#   2. Renames the local folder to match the new title.
#
set -uo pipefail

NB_ID="${1:?notebook_id required}"
NEW_TITLE="${2:?new title required}"
PROFILE="${3:?profile required}"
OLD_FOLDER="${4:?old folder path required}"

[[ -d "$OLD_FOLDER" ]] || { echo "ERROR: old folder not found: $OLD_FOLDER" >&2; exit 1; }

# Step 1: rename on NotebookLM side
output=$(nlm notebook rename "$NB_ID" "$NEW_TITLE" --profile "$PROFILE" 2>&1) || {
  echo "ERROR: nlm notebook rename failed: $output" >&2
  exit 2
}
echo "RENAMED on NotebookLM: $NEW_TITLE"

# Step 2: rename local folder (folder name = notebook title verbatim)
parent="$(dirname "$OLD_FOLDER")"
new_folder="$parent/$NEW_TITLE"

if [[ "$OLD_FOLDER" == "$new_folder" ]]; then
  echo "Local folder name already matches; nothing to move."
else
  if [[ -e "$new_folder" ]]; then
    echo "ERROR: target folder already exists: $new_folder" >&2
    exit 3
  fi
  mv "$OLD_FOLDER" "$new_folder"
  echo "RENAMED local folder: $new_folder"
fi

# Update the README.txt note inside the folder if present
readme="$new_folder/README.txt"
if [[ -f "$readme" ]]; then
  tmp=$(mktemp)
  awk -v t="$NEW_TITLE" 'NR==1 && /^NotebookLM tracking folder for:/ {print "NotebookLM tracking folder for: " t; next} {print}' "$readme" > "$tmp" && mv "$tmp" "$readme"
fi

echo
echo "DONE: $new_folder"
