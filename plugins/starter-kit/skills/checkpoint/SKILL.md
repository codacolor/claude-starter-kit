---
name: checkpoint
description: "Put a pin in the current project and create a context snapshot for future sessions. Use when the user says 'checkpoint', 'put a pin in it', 'save context', 'save state', 'session summary', 'wrap up', or when they're about to step away from a project and want to preserve where things stand. Also use proactively when a long session is ending and significant work was done that a future session would need to understand."
user_invocable: true
---

# Checkpoint — Project State Snapshot

Create a date-prefixed checkpoint file that captures where a project stands so a future Claude session can pick up seamlessly. This is like a "save game" for project work.

## When This Triggers

- User says `/checkpoint`, "put a pin in it", "save where we are", "wrap up"
- End of a significant work session where context would be lost
- Before switching to a different project or area

## Always Declare the Destination Before Writing

**Before writing anything, you MUST state where the checkpoint will be saved and get confirmation.** Sessions that touch multiple areas/projects make this ambiguous, and silently picking the wrong location buries the checkpoint where a future session will never find it.

Required format every time:

```
**Proposed checkpoint path:** `[full or relative path]`

**Alternatives considered:**
- `[other plausible path]` — [why I didn't pick this]
- `[another plausible path]` — [why I didn't pick this]

**Why I recommend the proposed path:**
- [Reason 1 — e.g., "Most of the substantive work this session touched X area's code"]
- [Reason 2 — e.g., "The deferred items are X-area-specific"]

Confirm path, or override?
```

Always offer at least one alternative when the choice isn't obvious. If only one path makes sense (e.g., the session was entirely inside one project), say so explicitly: "Only one obvious destination, no alternatives." Then still confirm before writing.

This rule is non-negotiable. Always be transparent about the destination every time checkpoint runs.

## What to Produce

### 1. Checkpoint File

Once the path is confirmed, write to `references/YYYYMMDD-checkpoint.md` inside the confirmed area or project folder. Use today's date. If a checkpoint with today's date already exists, append a letter suffix (`-b`, `-c`, etc.).

Use this template — adapt sections as needed, skip sections that don't apply, but keep the structure consistent:

```markdown
# Checkpoint — [Brief Title of Current Work]

**Date:** YYYY-MM-DD
**Area:** [Area or project name]
**Session focus:** [One sentence — what was the main goal this session]

## Status

[One-line summary: where does this project stand right now? e.g., "Prototype approved, ready for production build."]

## What Was Done

- [Concrete accomplishment — what changed, what was built, what was decided]
- [Another accomplishment]
- [Include file paths where helpful]

## What's Pending

- [ ] [Next task — specific enough that a fresh Claude instance could execute it]
- [ ] [Another pending task]
- [ ] [Include priority order — most important first]

## Key Decisions

Decisions that would be non-obvious to a fresh session and shouldn't be re-litigated:

- **[Decision topic]** — [What was decided and why]. [Alternative that was rejected, if relevant.]

## Architecture / Technical Context

[Only include if there's technical context a future session needs. Skip for non-technical work. Keep it brief — point to files rather than explaining code inline.]

- Key files: [list the 3-5 most important files and what they do]
- Dependencies / integrations: [external services, APIs, accounts involved]

## Resume Instructions

To pick back up, a new session should:

1. Read this checkpoint
2. [Specific first step — e.g., "Read the plan at .claude/plans/xyz.md"]
3. [Next step — e.g., "Start with task 4 in the implementation plan"]
```

### 2. Update CLAUDE.md

Add or update a `## Current Status` section in the area/project's CLAUDE.md. This should be exactly 1-3 lines — just enough for a future session to immediately know the state without reading the full checkpoint.

Format:
```markdown
## Current Status

[One-line status]. See [references/YYYYMMDD-checkpoint.md](references/YYYYMMDD-checkpoint.md) for full context.
```

If a `## Current Status` section already exists, replace its contents (don't append a second one). Place it right after the opening description, before any other sections.

## How to Gather Context

To write an accurate checkpoint, gather information from these sources (not all will be available — use what's there):

1. **The conversation itself** — what was discussed, decided, built
2. **CLAUDE.md** — current project description and any existing status
3. **Git status/log** — if it's a git repo, check recent commits and working tree state
4. **Todo list** — if a todo list exists in the current session, capture pending items
5. **Plan files** — check `.claude/plans/` for any active implementation plans
6. **Key files** — skim the most recently modified files to confirm what was built

Don't over-gather. The checkpoint should take 1-2 minutes to produce, not 10. If you have good context from the conversation, that's usually enough.

## Tone

Write checkpoints in clear, direct prose. No filler, no narrative. A future Claude instance reading this should be able to orient itself in under 30 seconds. Think of it as writing a handoff note to a colleague who's picking up your shift — they need to know what's happening, not how your day went.

## Edge Cases

- **No area/project CLAUDE.md exists**: Create a minimal one with the project description and current status. Follow the conventions in `~/.claude/rules/project-structure.md`.
- **No `references/` folder exists**: Create it.
- **Multiple checkpoints in one day**: Use letter suffixes (YYYYMMDD-checkpoint-b.md).
- **Tiny session with little to capture**: It's fine to write a short checkpoint. Even 5 lines of status is better than nothing if the user asked for one.
- **The project has an active plan file**: Reference the plan file path in "Resume Instructions" rather than duplicating its contents.
