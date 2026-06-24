# Claude Starter Kit

A friendly starting point for people new to Claude Code. It sets up a clean, organized workspace and gives you a few skills that make Claude genuinely useful from day one.

You get four skills:

- **`/onboard`** — sets up your workspace in one go (a tidy folder structure plus sensible conventions).
- **`/master-prompt`** — interviews you and builds a personal master prompt so Claude knows who you are and how you work.
- **`/notebooklm`** — turns PDFs, web pages, YouTube channels, and notes into a Google NotebookLM notebook you can chat with.
- **`/hold-my-hand`** — walks you through any task one step at a time when things feel overwhelming.
- **`/checkpoint`** — saves where a project stands so a future session can pick up right where you left off.

---

## Getting started from zero

### 1. Install Claude Code

Claude Code runs in your terminal. If you've never used a terminal, that's okay, you'll only need a couple of commands.

- Install [Node.js](https://nodejs.org) (the LTS version is fine).
- Then run:

  ```bash
  npm install -g @anthropic-ai/claude-code
  ```

- Start it once to sign in:

  ```bash
  claude
  ```

  Follow the prompt to log in (or paste an API key). You're now set up.

### 2. Install the kit

The easy way, one line:

```bash
curl -fsSL https://raw.githubusercontent.com/codacolor/claude-starter-kit/main/setup.sh | bash
```

Or do it by hand inside Claude Code:

```
/plugin marketplace add codacolor/claude-starter-kit
/plugin install starter-kit@claude-starter-kit
```

### 3. Set up your workspace

Open Claude Code and type:

```
/onboard
```

Answer a few quick questions (or say "just use defaults") and you'll have a real workspace in under a minute.

### 4. Build your master prompt

Then run:

```
/master-prompt
```

This is the highest-leverage thing you can do early. It teaches Claude who you are.

---

## What "a clean workspace" means

The kit organizes everything hub-and-spoke:

- **Areas/** — ongoing domains of work (Writing, Finances, Home).
- **Projects/** — time-bounded work with an end date.
- **Global Utilities/** — tools shared across Areas.
- **Templates/** — reusable starting points.

That's it. The structure keeps things findable as you grow, and Claude learns your conventions over time.

---

## For maintainers

This repo is both an Area in the author's workspace and a Claude Code plugin marketplace. The plugin lives in `plugins/starter-kit/`. To add a skill, drop it in `plugins/starter-kit/skills/<name>/` and bump the version in `plugins/starter-kit/.claude-plugin/plugin.json`.
