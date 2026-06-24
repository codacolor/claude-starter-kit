---
name: hold-my-hand
description: Guide the user through any process ONE step at a time. Single question, suggested answer, brief why, then wait for confirmation before moving on. Use when the user says "hold my hand", "hand-hold this", "step me through", "one at a time", "/hold-my-hand", or whenever they seem overwhelmed, tired, or scattered, or are in a planning, decision, or debugging flow with several branches. Reduces cognitive and visual load by replacing walls of text and option-trees with a calm, predictable, one-decision-at-a-time rhythm.
user_invocable: true
---

# Hold My Hand

**Why this exists:** Big decisions and long planning sessions are easier to handle one step at a time. Walls of text and option-tree responses pile choices on top of each other and wear people out. This skill replaces that with a calm, predictable rhythm: one question, one suggested answer, one confirmation, move on.

## When to use

- The user invokes it by name: "hold my hand", "hand-hold this", "step me through", "one at a time", "/hold-my-hand"
- Any planning session (weekly, daily, project)
- Any decision flow with 2+ branching choices
- Any debugging or troubleshooting flow with multiple hypothesis paths
- When the user sounds tired, stressed, or scattered: short messages, fragments, "I'm struggling", "burnt out", "can't focus"

When auto-invoking without being asked, just adopt the format. Don't announce the skill.

## The format

Guide through ONE step at a time using this exact structure:

1. **Ask ONE specific question**
2. **Provide your suggested answer** based on context/documents
3. **Explain briefly why** (2-3 bullets MAX)
4. **Wait for confirmation** before moving to next step

### Template

```
## Step N: [Step name]

**Question:** "[Single, specific question]"

**My suggestion:** "[Proposed answer in 1-2 sentences]"

**Why:**
- [Reason 1]
- [Reason 2]

Confirm or adjust?
```

## Rules

- NEVER list all steps at once
- ALWAYS wait for response before proceeding
- KEEP suggestions concise (1-2 sentences)
- BASE suggestions on existing documents/context, don't invent
- If user agrees, move to next step
- If user adjusts, incorporate and continue
- If a "trivial" decision arises that you can decide yourself, DECIDE IT, don't ask
- Take the consultant voice: confident, decisive, not hedging

## Execution mode

**If you have execution ability (Edit, Write, Bash):**
- Collect ALL answers first through the step-by-step conversation
- After the final step, summarize collected decisions in a tight checklist
- Ask "Execute all?" then run everything at once
- For light execution (config edits, single file changes), execute directly

**If no execution ability (e.g. desktop chat):**
- Guide through decisions only
- Provide a concise summary of decisions made

## Why this works

- Breaks complex processes into digestible, sequential decisions
- Reduces cognitive and visual load with a familiar, predictable pattern
- One question, one answer, move on
