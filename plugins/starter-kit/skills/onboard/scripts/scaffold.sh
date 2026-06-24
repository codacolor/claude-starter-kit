#!/usr/bin/env bash
# scaffold.sh — create a hub-and-spoke Claude Code workspace.
# Idempotent: never overwrites an existing CLAUDE.md, skips existing folders.
set -euo pipefail

PATH_ARG=""
NAME="Workspace"
REFS_DIR=""
AREAS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) PATH_ARG="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --refs-dir) REFS_DIR="$2"; shift 2 ;;
    --areas) AREAS="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$PATH_ARG" ]]; then
  echo "ERROR: --path is required" >&2
  exit 1
fi

# Expand a leading ~ to $HOME
WS="${PATH_ARG/#\~/$HOME}"

mkdir -p "$WS"/{Areas,Projects,"Global Utilities",Templates}
mkdir -p "$WS/.claude/rules"
mkdir -p "$WS/.claude/memory"

# Optional starter Areas
if [[ -n "$AREAS" ]]; then
  IFS=',' read -ra ARR <<< "$AREAS"
  for a in "${ARR[@]}"; do
    a_trimmed="$(echo "$a" | sed 's/^ *//; s/ *$//')"
    [[ -n "$a_trimmed" ]] && mkdir -p "$WS/Areas/$a_trimmed"
  done
fi

# Copy genericized convention rules into the workspace (path-scoped, auto-loaded)
if [[ -n "$REFS_DIR" && -d "$REFS_DIR" ]]; then
  for f in hub-and-spoke self-annealing memory-policy; do
    if [[ -f "$REFS_DIR/$f.md" && ! -f "$WS/.claude/rules/$f.md" ]]; then
      cp "$REFS_DIR/$f.md" "$WS/.claude/rules/$f.md"
    fi
  done
fi

# Seed the memory index
MEM="$WS/.claude/memory/MEMORY.md"
if [[ ! -f "$MEM" ]]; then
  cat > "$MEM" <<'EOF'
# Memory Index

One line per memory. Each memory is its own file in this folder.
Claude writes here automatically over time. Leave this comment in place.
EOF
fi

# Build the root CLAUDE.md from the template
TEMPLATE_OUT=""
render_claude_md() {
  cat <<EOF
# $NAME

This is my Claude Code workspace, organized hub-and-spoke. The folders below are the map; detailed conventions live in \`.claude/rules/\`.

## Layout

- **Areas/** — long-running domains of work. Each Area is self-contained and portable.
- **Projects/** — time-bounded work, date-prefixed (\`YYYYMMDD Name\`). Disposable when done.
- **Global Utilities/** — shared tools used across multiple Areas.
- **Templates/** — starter templates for new Areas and Projects.

## How to work here

- When I start something new, help me decide: is it an Area (ongoing), a Project (has an end), or a Global Utility (shared)?
- Keep this CLAUDE.md a lean map. Put detailed knowledge inside the relevant Area's own CLAUDE.md.
- Capture useful learnings as we go (see \`.claude/rules/self-annealing.md\`).
- Save cross-session context to memory (see \`.claude/rules/memory-policy.md\`).

## Learned Conventions

_(empty for now — this fills in over time as we work)_
EOF
}

if [[ -f "$WS/CLAUDE.md" ]]; then
  render_claude_md > "$WS/CLAUDE.md.new"
  TEMPLATE_OUT="CLAUDE.md.new (existing CLAUDE.md was left untouched)"
else
  render_claude_md > "$WS/CLAUDE.md"
  TEMPLATE_OUT="CLAUDE.md"
fi

# AGENTS.md pointer for non-Claude models
if [[ ! -f "$WS/AGENTS.md" ]]; then
  cat > "$WS/AGENTS.md" <<'EOF'
# Workspace Documentation

All conventions live in CLAUDE.md and `.claude/`.

- **CLAUDE.md** — workspace map and how to work here
- **`.claude/rules/`** — conventions (hub-and-spoke, self-annealing, memory)
- **`.claude/memory/`** — cross-session memory

Read CLAUDE.md first.
EOF
fi

echo "Workspace scaffolded at: $WS"
echo "Wrote: $TEMPLATE_OUT"
echo "Structure:"
( cd "$WS" && find . -maxdepth 2 -not -path '*/.git/*' | sort | sed 's|^\./||' | grep -v '^\.$' )
