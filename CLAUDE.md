# Claude Starter Kit (Area)

A Claude Code plugin Cody hands to friends who are new to Claude Code. This folder is BOTH an Area in the workspace and a public plugin marketplace (repo `codacolor/claude-starter-kit`, pushed to GitHub `main`).

The README.md here is friend-facing (getting started from zero). This CLAUDE.md is the maintainer view.

## What ships

A single plugin, `starter-kit`, bundling five skills:

- **onboard** (original) — scaffolds a hub-and-spoke workspace + genericized conventions. Centerpiece. `skills/onboard/scripts/scaffold.sh` does the deterministic folder/CLAUDE.md creation.
- **master-prompt** — vendored from `codacolor/master-prompt`. Targets `~/.claude/CLAUDE.md` and uses a `<skill_dir>` placeholder, so it's plugin-safe as-is.
- **notebooklm** — vendored from `codacolor/claude-notebooklm`. Scrubbed of hardcoded `~/.claude/skills/...` paths → `${CLAUDE_PLUGIN_ROOT}/skills/notebooklm/...` so its scripts resolve for plugin users. Profile name defaults to `default` (no prompt).
- **hold-my-hand** — genericized from Cody's global skill (PTVS/medical/personal refs removed).
- **checkpoint** — vendored from Cody's global skill (personal refs scrubbed).

## Conventions

- **Vendored skills must be plugin-safe.** Any reference to `~/.claude/skills/<name>/...` breaks for friends (that path only exists for the author). Use `${CLAUDE_PLUGIN_ROOT}/skills/<name>/...` for script calls. `~/.claude/CLAUDE.md` (the user's global config) is a legitimate target and stays as-is.
- **Genericize anything personal.** No Cody/Codacolor/Modal/Supabase/medical references in friend-facing skills. Grep before committing: `grep -rinE "cody|codacolor|antigravity|modal|supabase|/Users/cody" plugins/`.
- **Newcomer ergonomics win over flexibility.** Prefer sensible silent defaults over questions a first-timer can't answer (e.g. notebooklm profile defaults to `default` instead of asking).

## How to add a skill

1. Drop it in `plugins/starter-kit/skills/<name>/` (genericize + make plugin-safe).
2. Bump `version` in `plugins/starter-kit/.claude-plugin/plugin.json`.
3. Mention it in `onboard/SKILL.md` handoff and the top-level `README.md`.
4. Commit + `git push origin main`. Friends pull it automatically next install/update.

## Publish / test

- Repo: `gh repo view codacolor/claude-starter-kit`
- Validate marketplace resolves: `claude plugin marketplace add codacolor/claude-starter-kit` then `claude plugin marketplace remove claude-starter-kit` (remove after, to avoid name clashes with Cody's own global skills).
- Friend install: one-liner in README runs `setup.sh` (marketplace add + install).

## Backlog

- `claude-video` (`codacolor/claude-video`) is the obvious next add when wanted.
- Candidate convention adds later: `decision-options`, `self-questioning` (genericized).
