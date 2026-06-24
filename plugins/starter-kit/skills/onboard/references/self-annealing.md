# Self-Annealing — Capture Learnings As You Go

The workspace should get smarter over time. When something useful is learned during a session, capture it so a future session benefits. This works both ways: learn from mistakes so they don't recur, and record new discoveries so they're available later.

## When to capture

**Something went wrong or surprised us:**
- The user corrected an approach ("no, do it this way")
- A fix revealed a non-obvious rule or constraint
- A task failed because of an undocumented requirement

**Something new was discovered:**
- A configuration value, account detail, or path a future session will need
- A quirk or limit of an external tool
- A decision and the reason behind it (so we don't relitigate it later)

**The user said so:**
- "Remember this", "save this", "note this"

## What NOT to capture

- Typo fixes or one-off debugging
- Anything obvious from reading the files
- Temporary workarounds that won't recur

## Where it goes

Ask: "What does this apply to?"

| Scope | Destination |
|---|---|
| This whole workspace, a hard rule | Root `CLAUDE.md` under `## Learned Conventions` |
| One Area only | That Area's `CLAUDE.md` under `## Learned Conventions` |
| Personal context across sessions (preferences, references, reminders) | `.claude/memory/` (see memory-policy.md) |

## How to write it

- Be concrete: include the actual command, path, or value
- One learning per entry
- Bullets, not paragraphs
- Lead with the problem, then the fix

## Surface before saving

Don't silently rewrite conventions. When a learning comes up, mention it and let the user confirm before recording it. The user decides what gets kept.
