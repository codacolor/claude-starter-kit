#!/usr/bin/env bash
#
# Resolve a notebook by name → notebook ID, ensure a per-notebook local folder
# exists, and snapshot the notebook's current source list into a fresh
# ledger.tsv if one doesn't already exist (or is empty).
#
# This is the entry point for ANY modify-existing operation. It silently
# adopts notebooks created before the skill was set up (no manual register step).
#
# Usage: discover.sh <notebook_name_or_id> [<profile>] [<base_folder>]
#
# Profile and base_folder default to values in ~/.config/claude-notebooklm/state.json.
#
# Outputs (stdout, key=value pairs the caller can eval):
#   NOTEBOOK_ID=<uuid>
#   NOTEBOOK_NAME=<title>
#   NOTEBOOK_FOLDER=<absolute path>
#   IS_FRESH_SCAFFOLD=true|false
#
set -uo pipefail

STATE_FILE="$HOME/.config/claude-notebooklm/state.json"

# Read defaults from state.json
PROFILE_FROM_STATE=""
BASE_FROM_STATE=""
if [[ -f "$STATE_FILE" ]]; then
  PROFILE_FROM_STATE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('profile',''))" 2>/dev/null || echo "")
  BASE_FROM_STATE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('base_folder',''))" 2>/dev/null || echo "")
fi

QUERY="${1:?notebook name or ID required}"
PROFILE="${2:-${PROFILE_FROM_STATE:-default}}"
BASE_FOLDER="${3:-${BASE_FROM_STATE:-$HOME/Documents/NotebookLM}}"

mkdir -p "$BASE_FOLDER"

list_json=$(nlm notebook list --json --profile "$PROFILE" 2>&1) || {
  echo "ERROR: nlm notebook list failed: $list_json" >&2
  exit 1
}

# Try exact UUID match
nb_id=""
nb_name=""
if [[ "$QUERY" =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ ]]; then
  match=$(echo "$list_json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
items = data if isinstance(data, list) else data.get('notebooks', data.get('items', []))
q = '$QUERY'
for nb in items:
    if nb.get('id') == q or nb.get('notebook_id') == q:
        print(f\"{nb.get('id', nb.get('notebook_id'))}|{nb.get('title', nb.get('name', ''))}\")
        break
" 2>/dev/null)
  if [[ -n "$match" ]]; then
    nb_id="${match%|*}"
    nb_name="${match#*|}"
  fi
fi

# Fuzzy title match (case-insensitive substring)
if [[ -z "$nb_id" ]]; then
  matches=$(echo "$list_json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
items = data if isinstance(data, list) else data.get('notebooks', data.get('items', []))
q = '''$QUERY'''.lower()
hits = []
for nb in items:
    title = nb.get('title', nb.get('name', ''))
    if q in title.lower():
        hits.append((nb.get('id', nb.get('notebook_id', '')), title))
for nbid, t in hits:
    print(f'{nbid}|{t}')
" 2>/dev/null)
  count=$(echo "$matches" | grep -c "|" || true)
  if [[ "$count" -eq 0 ]]; then
    echo "ERROR: no notebook matches '$QUERY'. Run 'nlm notebook list' to see options." >&2
    exit 3
  elif [[ "$count" -gt 1 ]]; then
    echo "ERROR: ambiguous match for '$QUERY':" >&2
    echo "$matches" | sed 's/^/  - /' >&2
    echo "  Be more specific or pass the UUID." >&2
    exit 4
  fi
  nb_id="${matches%|*}"
  nb_name="${matches#*|}"
fi

# Locate or create the per-notebook folder.
# Folder name uses the notebook title verbatim — simpler than the Cody-side
# "NotebookLM Sync — <name>" prefix.
FOLDER="$BASE_FOLDER/$nb_name"
fresh="false"
if [[ ! -d "$FOLDER" ]]; then
  fresh="true"
  mkdir -p "$FOLDER"
  echo "SCAFFOLDED: $FOLDER" >&2
fi

LEDGER="$FOLDER/ledger.tsv"
FAILURES="$FOLDER/failures.tsv"

# Ensure ledger + failures files exist with headers
if [[ ! -s "$LEDGER" ]]; then
  printf "group\tsource_type\tcanonical_id\tsource_id\tadded_at\ttitle\n" > "$LEDGER"
fi
if [[ ! -s "$FAILURES" ]]; then
  printf "group\tsource_type\tcanonical_id\tfailed_at\terror\n" > "$FAILURES"
fi

# If ledger has only the header, snapshot the notebook's existing sources into
# it so future ops are idempotent.
ledger_data_rows=$(awk 'NR>1 && NF>0' "$LEDGER" | wc -l | tr -d ' ')
if [[ "$ledger_data_rows" -eq 0 ]]; then
  src_json=$(nlm source list "$nb_id" --json --profile "$PROFILE" 2>&1) || {
    echo "WARN: could not snapshot existing sources (nlm source list failed): $src_json" >&2
  }
  if [[ -n "$src_json" && "$src_json" != "ERROR"* ]]; then
    echo "$src_json" | python3 -c "
import sys, json
from datetime import datetime, timezone
ts = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
data = json.load(sys.stdin)
items = data if isinstance(data, list) else data.get('sources', data.get('items', []))
for s in items:
    sid = s.get('id', s.get('source_id', ''))
    title = (s.get('title', s.get('name', '')) or '').replace('\t',' ').replace('\n',' ')
    src_type = s.get('source_type', s.get('type', 'unknown'))
    canonical = s.get('url', s.get('canonical_id', sid))
    print(f'imported\t{src_type}\t{canonical}\t{sid}\t{ts}\t{title}')
" >> "$LEDGER" 2>/dev/null
    snapshot_count=$(awk 'NR>1 && NF>0' "$LEDGER" | wc -l | tr -d ' ')
    echo "SNAPSHOTTED: $snapshot_count existing sources into ledger" >&2
  fi
fi

echo "NOTEBOOK_ID=$nb_id"
echo "NOTEBOOK_NAME=$nb_name"
echo "NOTEBOOK_FOLDER=$FOLDER"
echo "IS_FRESH_SCAFFOLD=$fresh"
