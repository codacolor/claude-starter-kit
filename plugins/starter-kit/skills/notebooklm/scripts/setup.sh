#!/usr/bin/env bash
#
# First-run setup utility for the claude-notebooklm skill.
#
# Subcommands:
#   setup.sh check
#       Print a status report (one fact per line) so Claude can read it
#       and walk the user through anything missing. Always exits 0; the
#       presence/absence of "missing" lines tells the caller what to do.
#
#   setup.sh save-state <profile> <base_folder>
#       Persist the user's choices to ~/.config/claude-notebooklm/state.json.
#       Creates the config dir if needed.
#
#   setup.sh state
#       Print the current state.json contents. Exits 0 if found, 1 if not.
#
#   setup.sh ensure-folder <path>
#       Create the base notebook folder if it doesn't exist.
#
set -uo pipefail

CONFIG_DIR="$HOME/.config/claude-notebooklm"
STATE_FILE="$CONFIG_DIR/state.json"

cmd="${1:-check}"

case "$cmd" in
  check)
    echo "=== claude-notebooklm setup check ==="

    # Homebrew
    if command -v brew >/dev/null 2>&1; then
      echo "ok: brew installed ($(brew --version 2>/dev/null | head -1))"
    else
      echo "missing: brew"
      echo "  install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi

    # uv (Python package/tool manager — used to install nlm)
    if command -v uv >/dev/null 2>&1; then
      echo "ok: uv installed ($(uv --version 2>/dev/null))"
    else
      echo "missing: uv"
      echo "  install: brew install uv"
    fi

    # nlm CLI
    if command -v nlm >/dev/null 2>&1; then
      echo "ok: nlm installed ($(nlm --version 2>/dev/null | head -1))"
    else
      echo "missing: nlm"
      echo "  install: uv tool install notebooklm-mcp-cli"
    fi

    # yt-dlp (only required for YouTube channel/video sources)
    if command -v yt-dlp >/dev/null 2>&1; then
      echo "ok: yt-dlp installed ($(yt-dlp --version 2>/dev/null))"
    else
      echo "missing: yt-dlp"
      echo "  install: brew install yt-dlp"
    fi

    # State file
    if [[ -f "$STATE_FILE" ]]; then
      echo "ok: state file found at $STATE_FILE"
      cat "$STATE_FILE" | sed 's/^/    /'

      # Check auth for the saved profile
      profile=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('profile',''))" 2>/dev/null || echo "")
      if [[ -n "$profile" ]] && command -v nlm >/dev/null 2>&1; then
        if nlm login --check --profile "$profile" >/dev/null 2>&1; then
          echo "ok: profile '$profile' authenticated"
        else
          echo "missing: auth for profile '$profile'"
          echo "  install: nlm login --profile $profile"
        fi
      fi
    else
      echo "missing: state file (first run not complete)"
      echo "  next: choose a profile name and base folder, then run save-state"
    fi
    ;;

  save-state)
    profile="${2:?profile name required}"
    base_folder="${3:?base folder path required}"

    # Expand ~ if present
    base_folder="${base_folder/#\~/$HOME}"

    mkdir -p "$CONFIG_DIR"
    mkdir -p "$base_folder"

    cat > "$STATE_FILE" <<EOF
{
  "profile": "$profile",
  "base_folder": "$base_folder",
  "version": 1,
  "setup_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

    echo "saved: $STATE_FILE"
    cat "$STATE_FILE"
    ;;

  state)
    if [[ ! -f "$STATE_FILE" ]]; then
      echo "no state file at $STATE_FILE" >&2
      exit 1
    fi
    cat "$STATE_FILE"
    ;;

  ensure-folder)
    folder="${2:?folder path required}"
    folder="${folder/#\~/$HOME}"
    mkdir -p "$folder"
    echo "ok: $folder"
    ;;

  *)
    echo "ERROR: unknown subcommand '$cmd'" >&2
    echo "usage: setup.sh {check|save-state|state|ensure-folder}" >&2
    exit 1
    ;;
esac
