---
name: onboard
description: Set up a clean, well-organized Claude Code workspace in one go. Scaffolds a hub-and-spoke folder structure (Areas, Projects, Global Utilities, Templates), writes a personalized root CLAUDE.md, installs a few sensible conventions, and seeds a memory folder. Use on a fresh machine or empty folder, or whenever the user says "onboard me", "set up my workspace", "/onboard", "get me started with Claude Code", "scaffold my workspace", or "I'm new to Claude Code, help me set up". Ends by pointing the user to the other starter-kit skills.
user_invocable: true
---

# onboard

This is the front door for someone new to Claude Code. Your job: get them from an empty folder to a clean, organized workspace they understand, with as little friction as possible.

## The model you're installing: hub-and-spoke

One workspace folder is the **hub**. Inside it:

- **Areas/** — long-running domains of work (e.g. "Writing", "Finances", "Home"). Each Area is self-contained.
- **Projects/** — time-bounded work with a clear end, date-prefixed (`YYYYMMDD Name`). Disposable when done.
- **Global Utilities/** — shared tools or infrastructure used across multiple Areas.
- **Templates/** — starter templates for new Areas and Projects.

The root `CLAUDE.md` is a lean map of the workspace, not an encyclopedia. Detailed conventions live in `.claude/rules/`.

See `references/hub-and-spoke.md` for the full philosophy. Don't dump it on the user. Summarize in a sentence or two.

## Flow

### 1. Light interview (3-4 questions max)

Ask these one at a time, conversational, with a suggested default for each. Offer a "just use defaults" escape hatch up front for anyone who feels overwhelmed.

1. **Where should the workspace live?** Suggest `~/Workspace` (or `~/Documents/Workspace`). Accept any absolute path.
2. **What should we call it?** Suggest "Workspace". This becomes the title in CLAUDE.md.
3. **What kinds of things will you use Claude for?** Free-form. Use their answer to pre-create 1-3 starter Areas (e.g. "writing" → `Areas/Writing/`). If unsure, create none.

If they say "just use defaults" at any point, stop asking and use: path `~/Workspace`, name "Workspace", no starter Areas.

### 2. Scaffold

Run the script. It creates the folder structure, writes a personalized root `CLAUDE.md` and `AGENTS.md` pointer, installs the convention rules into `.claude/rules/`, and seeds a memory folder.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/onboard/scripts/scaffold.sh" \
  --path "<absolute workspace path>" \
  --name "<workspace name>" \
  --refs-dir "${CLAUDE_PLUGIN_ROOT}/skills/onboard/references" \
  --areas "Writing,Finances"   # optional, comma-separated; omit if none
```

If `CLAUDE_PLUGIN_ROOT` is not set in the environment, use the skill's own base directory (the folder this SKILL.md lives in, minus `/skills/onboard`) as the plugin root, or pass `--refs-dir` pointing directly at this skill's `references/` folder.

The script is idempotent: it never overwrites an existing `CLAUDE.md` (it writes `CLAUDE.md.new` instead and tells the user), and it skips folders that already exist.

### 3. Confirm and hand off

After scaffolding, show the user the tree that was created (a quick `ls` or the script's summary). Then tell them the three other skills they now have, in plain language:

- **`/master-prompt`** — builds a personal master prompt so Claude knows who they are and how they work. Strongly recommend they run this next.
- **`/notebooklm`** — turns PDFs, web pages, YouTube channels, and notes into a NotebookLM notebook they can chat with.
- **`/hold-my-hand`** — any time a task feels overwhelming, this walks them through it one step at a time.

Keep the handoff short and encouraging. They just went from zero to a real workspace.

## Notes

- This skill runs *inside* Claude Code, so it cannot install Claude Code itself. Installing the host (and any API key/billing) is covered in the kit's README. Assume the user is already past that.
- Don't lecture. A first-timer wants momentum, not a manual. Decide trivial things yourself.
