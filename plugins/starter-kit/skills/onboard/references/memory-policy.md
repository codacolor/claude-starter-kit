# Memory Policy — Cross-Session Context

Memory is for things that help Claude work better with you across sessions. It lives in `.claude/memory/`, one fact per file, with a one-line pointer in `MEMORY.md`. `MEMORY.md` is the index loaded each session.

## What belongs in memory

- **Who you are** — your role, preferences, how you like to work
- **Feedback** — corrections and confirmed approaches ("don't do X", "yes, keep doing Y"), with the reason why
- **References** — pointers to external things (a dashboard, an account, a document to track)
- **Time-sensitive context** — a deadline, a decision in flight, a workaround to remove once something is fixed

## What does NOT belong in memory

- Project-specific config, IDs, or file paths (those go in the relevant Area's CLAUDE.md)
- Architecture or how-something-works details (those go in CLAUDE.md)
- Anything obvious from reading the files

## How to write a memory

Each memory is one file with simple frontmatter:

```markdown
---
name: short-kebab-case-slug
description: one-line summary used to decide relevance later
type: user | feedback | reference | project
---

The fact. For feedback, add why it matters and how to apply it.
```

After writing the file, add one line to `MEMORY.md`:

```
- [Title](slug.md) — short hook
```

## Keep it tidy

- Before saving, check for an existing file that already covers it. Update that one instead of duplicating.
- Delete memories that turn out to be wrong.
- Keep `MEMORY.md` short. It loads every session.
