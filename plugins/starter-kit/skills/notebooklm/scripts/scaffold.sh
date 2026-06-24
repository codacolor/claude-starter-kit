#!/usr/bin/env bash
#
# Scaffold a per-notebook tracking folder with ledger.tsv and failures.tsv.
# Used to keep idempotency state for "have we added this source already?".
#
# Usage: scaffold.sh <folder_path> <notebook_name> <notebook_id> <profile>
#
# Idempotent — existing ledger/failures files are not overwritten.
#
set -uo pipefail

FOLDER="${1:?folder path required}"
NB_NAME="${2:?notebook name required}"
NB_ID="${3:?notebook ID required}"
PROFILE="${4:?profile required}"

mkdir -p "$FOLDER"

# Ledger and failures TSV headers (only created if files don't exist or are empty)
if [[ ! -s "$FOLDER/ledger.tsv" ]]; then
  printf "group\tsource_type\tcanonical_id\tsource_id\tadded_at\ttitle\n" > "$FOLDER/ledger.tsv"
fi
if [[ ! -s "$FOLDER/failures.tsv" ]]; then
  printf "group\tsource_type\tcanonical_id\tfailed_at\terror\n" > "$FOLDER/failures.tsv"
fi

# Lightweight info file so the user can see what this folder is for if they
# stumble into it. No Claude-specific scaffolding — just a plain text note.
cat > "$FOLDER/README.txt" <<EOF
NotebookLM tracking folder for: $NB_NAME

Notebook ID: $NB_ID
Profile: $PROFILE

This folder was created by the claude-notebooklm skill. It tracks which sources
have been added to the notebook so re-runs don't double-add.

Files:
  ledger.tsv   = every source ever added (idempotency record)
  failures.tsv = sources NotebookLM rejected (e.g., copyright-blocked videos)
  sources/     = copies of any local files (PDFs, etc.) added to the notebook
  texts/       = pasted-text snippets staged for upload

Safe to keep, safe to delete. Deleting it just means the skill loses memory of
what's in the notebook. Re-adding sources will re-snapshot from NotebookLM.
EOF

echo "SCAFFOLDED: $FOLDER"
