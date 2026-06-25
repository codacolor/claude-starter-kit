#!/usr/bin/env bash
#
# Verify dependencies and authentication before running a notebook operation.
# Reads profile from ~/.config/claude-notebooklm/state.json unless overridden.
#
# Usage: preflight.sh [<profile>] [--skip-yt-dlp]
#
# Exits 0 if ready. Exits 1 with a clear remediation message otherwise — the
# message tells the user (or Claude) which install/auth command to run next.
#
set -uo pipefail

STATE_FILE="$HOME/.config/claude-notebooklm/state.json"

# Read profile from state.json if present
PROFILE_FROM_STATE=""
if [[ -f "$STATE_FILE" ]]; then
  PROFILE_FROM_STATE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('profile',''))" 2>/dev/null || echo "")
fi

PROFILE="${1:-${PROFILE_FROM_STATE:-default}}"
SKIP_YTDLP="false"
[[ "${2:-}" == "--skip-yt-dlp" ]] && SKIP_YTDLP="true"

fail() {
  echo "PREFLIGHT FAIL: $*" >&2
  echo "Run: bash ${CLAUDE_PLUGIN_ROOT}/skills/notebooklm/scripts/setup.sh check" >&2
  echo "  to see what's missing and how to fix it." >&2
  exit 1
}

command -v nlm >/dev/null 2>&1 || fail "nlm CLI not installed. Install: uv tool install notebooklm-mcp-cli"

if [[ "$SKIP_YTDLP" != "true" ]]; then
  command -v yt-dlp >/dev/null 2>&1 || fail "yt-dlp not installed (needed for YouTube sources). Install: brew install yt-dlp"
fi

# nlm login --check exits non-zero on bad auth
if ! nlm login --check --profile "$PROFILE" >/dev/null 2>&1; then
  fail "Profile '$PROFILE' not authenticated. Run: nlm login --profile $PROFILE"
fi

echo "OK: nlm $(nlm --version 2>/dev/null | head -1), profile '$PROFILE' authenticated"
