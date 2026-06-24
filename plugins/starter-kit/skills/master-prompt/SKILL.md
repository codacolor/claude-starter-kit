---
name: master-prompt
description: Build, install, and maintain your personal Master Prompt for Claude Code. First run walks you through an interview and installs it. Subsequent runs update it. Triggers on "master prompt", "build my master prompt", "update my master prompt", "bake master prompt".
user_invocable: true
---

# Master Prompt Skill

Build and maintain a personal Master Prompt — persistent instructions that tell Claude who you are, what you do, how you work, and how you want it to respond.

## Trigger Detection

### First Run (Setup)
**Triggers:** "master prompt", "build my master prompt", "set up my master prompt", "get started"
**Condition:** `~/.claude/CLAUDE.md` does not exist OR does not contain `<!-- MASTER_PROMPT_START -->` marker.
**Action:** Run the full onboarding interview → build → install → bake.

### Update
**Triggers:** "update my master prompt", "change my master prompt", "edit my master prompt"
**Condition:** Master prompt markers exist in `~/.claude/CLAUDE.md`.
**Action:** Show current master prompt → walk through changes one at a time → update → re-bake.

### Bake Only
**Triggers:** "bake master prompt", "bake for desktop", "export master prompt"
**Condition:** Master prompt markers exist in `~/.claude/CLAUDE.md`.
**Action:** Run `python3 <skill_dir>/scripts/bake.py` to refresh `~/Desktop/Master_Prompt_Baked.txt`.

---

## First Run: Onboarding Interview

Use the **Hold My Hand** format for the entire interview. This is critical — do NOT dump all questions at once.

### Hold My Hand Protocol

For every single question in the interview:

1. **Ask ONE specific question**
2. **Provide a suggested answer** if you can infer one from context, or a clear example if you can't
3. **Explain briefly why** this matters (2-3 bullets max)
4. **Wait for confirmation** before moving to the next question

**Rules:**
- NEVER list multiple questions at once — one at a time only
- ALWAYS wait for the user's response before proceeding
- KEEP suggestions concise (1-2 sentences)
- If the user confirms, move to the next question
- If the user adjusts, incorporate their changes and continue
- If a section clearly doesn't apply (e.g., they're a student, not a business owner), say so and ask if they want to skip it

### Interview Sections

Walk through these sections sequentially. Within each section, ask questions one at a time.

**Section 1: Personal**
- What's your name?
- What's your role / what do you do?
- How do you want to use AI? (automate tasks, think through strategy, write content, build software, offload cognitive load, etc.)
- What are your strengths?
- What are your weaknesses or constraints?

**Section 2: Company / Organization**
- What's the name of your company or organization? (Or independent/freelance/student?)
- How long have you been doing this?
- Who else is on your team? What are their roles?
- What market do you serve? Who is your ideal customer/client/audience?
- What outcome do you deliver for them?
- What makes you different from competitors?

**Section 3: Products & Services**
- What do you currently sell or offer? (Include pricing if relevant)
- What are you building or launching next?

**Section 4: Culture & Mission**
- What are your core values?
- What's your mission?
- What's your big, hairy, audacious goal (BHAG)?

**Section 5: Response Preferences**
- How do you like AI to respond? (concise vs. detailed, formal vs. casual, challenge my thinking, etc.)
- Are there behaviors you always want to see? (e.g., "Always ask clarifying questions before starting," "Always flag uncertainty," etc.)
- Are there behaviors you want to avoid? (e.g., "Don't use emojis," "Don't over-explain," etc.)

**Adaptation:** Not everyone runs a business. If the person is a student, hobbyist, employee, or individual contributor — skip or condense Sections 2-4 as appropriate. The goal is to capture *who they are and how they want to work with AI*.

### After the Interview: Draft & Review

Once all questions are answered, compile everything into a Master Prompt using this format:

```markdown
<!-- MASTER_PROMPT_START -->
# MASTER PROMPT

## 1. PERSONAL
Name:
Role:
How I want to use AI:
Strengths:
Weaknesses / Constraints:

## 2. COMPANY / ORGANIZATION
Name:
Established:
Team:
Market served:
Ideal customer:
Outcome delivered:
Differentiators:

## 3. PRODUCTS & SERVICES
[Current offerings with pricing]
[Upcoming launches]

## 4. CULTURE & MISSION
Core values:
Mission:
BHAG:

## 5. RESPONSE PREFERENCES
[Specific behavioral instructions for AI]
<!-- MASTER_PROMPT_END -->
```

**Only include sections that came up in the interview.** If sections were skipped, omit them.

Present the full draft and ask: **"Review this — anything you'd change?"**

Use the Hold My Hand format for revisions too — walk through each requested change one at a time. Once the user approves, proceed to installation.

### Installation

1. **Check for existing `~/.claude/CLAUDE.md`:**
   - If it exists and has content, show the user what's there and ask: "You already have a CLAUDE.md. I'll add your Master Prompt above your existing content, separated by a line. OK?"
   - If it doesn't exist, create it.

2. **Write the master prompt** to `~/.claude/CLAUDE.md`. If existing content is present, prepend the master prompt above it with a `---` separator.

3. **Bake to Desktop:** Run `python3 <skill_dir>/scripts/bake.py` to create `~/Desktop/Master_Prompt_Baked.txt`.

4. **Explain what just happened:**

> **You're all set.** Here's what I did:
>
> - **Installed your Master Prompt** to `~/.claude/CLAUDE.md` — this loads automatically in every Claude Code conversation.
> - **Exported a copy** to `~/Desktop/Master_Prompt_Baked.txt` — paste this into Claude Desktop, OpenAI Codex CLI, Cursor, or any other AI tool that accepts custom instructions. (Note: the consumer ChatGPT app's Custom Instructions field is too short for a full Master Prompt — use Codex for OpenAI.)
>
> **For per-tool paste-ready walkthroughs** (Claude Desktop, ChatGPT, Codex, Cursor, Windsurf, Gemini, Copilot), see the README:
> https://github.com/codacolor/master-prompt#using-it-with-other-ai-tools
>
> **Going forward:**
> - To update your master prompt, just say `/master-prompt` and tell me what changed.
> - Every update automatically refreshes both your Claude Code config and the Desktop export.
> - You can also edit `~/.claude/CLAUDE.md` directly in any text editor.

---

## Update Flow

When the user wants to update their master prompt:

1. **Read current master prompt** from `~/.claude/CLAUDE.md` (content between the `<!-- MASTER_PROMPT_START -->` and `<!-- MASTER_PROMPT_END -->` markers).

2. **Show it to them:** "Here's your current Master Prompt: [display it]. What would you like to change?"

3. **Walk through changes using Hold My Hand format.** For each change:
   - Confirm what they want to change
   - Show the proposed edit
   - Wait for approval
   - Apply the edit

4. **After all changes:** Show the updated master prompt in full. Ask: "Everything look good?"

5. **On approval:**
   - Update `~/.claude/CLAUDE.md` (edit content between markers)
   - Run `python3 <skill_dir>/scripts/bake.py` to refresh Desktop export
   - Confirm: "Master Prompt updated and re-exported to Desktop."

---

## Bake Pipeline

The bake script (`scripts/bake.py`) does two things:

1. Reads the master prompt content from `~/.claude/CLAUDE.md` (between markers)
2. Writes a clean copy to `~/Desktop/Master_Prompt_Baked.txt`

This gives the user a ready-to-paste version for:
- Claude Desktop app (Settings > Profile > Custom Instructions)
- OpenAI Codex CLI (save as `~/.codex/AGENTS.md`)
- Cursor, Windsurf, or any other AI tool that accepts system instructions

Note: the consumer ChatGPT app's Custom Instructions field is too short to hold a full Master Prompt — direct OpenAI users to Codex CLI instead.

Run the bake script after every install or update:
```bash
python3 <skill_dir>/scripts/bake.py
```

Replace `<skill_dir>` with the actual path to this skill's directory (wherever this SKILL.md file lives — use the same directory).
