---
name: notebooklm
description: Create, modify, and manage Google NotebookLM notebooks via the `nlm` CLI. Supports YouTube channels and videos, web URLs, local files (PDFs/txt/md/docx), pasted text, and Google Drive docs. Handles every operation: build new notebooks, add sources to existing notebooks, remove sources, list contents, rename notebooks. Use whenever the user wants to work with NotebookLM. Triggers include "set up a new notebook for X", "add this PDF / URL / text / channel / Drive doc to my <Name> notebook", "remove the source about Y", "list my notebooks", "what's in my X notebook?", "rename my notebook", or "make a notebook from these PDFs". On first run, walks the user through a one-time guided setup (installs nlm CLI + yt-dlp, signs into NotebookLM in their browser, picks a folder for notebooks).
---

# notebooklm

One skill that handles every NotebookLM operation. Built on the public `nlm` CLI (`notebooklm-mcp-cli` on PyPI). Per-user profile-based auth.

## First-run gate (CRITICAL — check this before ANY other workflow)

Before handling any user request, check whether the user has completed setup:

```bash
bash ~/.claude/skills/notebooklm/scripts/setup.sh state
```

If this exits non-zero (no state file found), STOP the requested workflow and run the **First-run setup walkthrough** below first. After setup completes, return to the user's original request.

If the state file exists, continue to the requested workflow.

## First-run setup walkthrough

Walk the user through this **one prompt at a time**. Wait for their reply between steps. Be friendly and brief — this is someone's first interaction with the skill.

### Step 1 — Welcome and consent

Tell the user something like:

> Hey, looks like this is your first time using the NotebookLM skill. Quick one-time setup before we start. We'll do four things:
>
> 1. Install two small command-line tools (`nlm` for NotebookLM, `yt-dlp` for YouTube)
> 2. Sign you into NotebookLM in your browser
> 3. Pick a folder on your computer to store notebook tracking files
> 4. Save your settings
>
> Takes about 5 minutes. Ready to go?

Wait for confirmation before proceeding.

### Step 2 — Check what's already installed

Run:

```bash
bash ~/.claude/skills/notebooklm/scripts/setup.sh check
```

Read the output. For each line that starts with `missing:`, you'll walk the user through that step. For `ok:` lines, skip ahead.

### Step 3 — Install Homebrew (if missing)

If `brew` is missing, tell the user:

> First we need Homebrew, which is the standard package manager for Mac. Paste this into your Terminal app and run it:
>
> ```
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
> ```
>
> It'll ask for your password and take a few minutes. Let me know when it's done.

Wait for them to confirm. Then re-run `setup.sh check` to verify.

### Step 4 — Install `uv` (if missing)

If `uv` is missing, run:

```bash
brew install uv
```

Show the user this is what you're running. Wait for it to finish.

### Step 5 — Install the `nlm` CLI (if missing)

If `nlm` is missing, run:

```bash
uv tool install notebooklm-mcp-cli
```

Verify with `nlm --version`.

### Step 6 — Install `yt-dlp` (if missing)

If `yt-dlp` is missing, run:

```bash
brew install yt-dlp
```

(This one is only needed for YouTube sources, but it's small and quick to install up front.)

### Step 7 — Pick a profile name

Tell the user:

> Now we need to sign you into NotebookLM. The `nlm` CLI lets you save multiple Google accounts as separate "profiles" so you can switch between them. For most people, one profile is enough.
>
> What do you want to call your profile? I suggest `default` if you're not sure.

Wait for their answer. Most users will say "default" — that's fine.

### Step 8 — Sign in

Run:

```bash
nlm login --profile <profile_name>
```

Tell the user:

> A browser window is going to open. Sign in with the Google account that has access to NotebookLM. After you finish signing in, come back here and tell me you're done.

Wait for them to confirm. Then verify with:

```bash
nlm login --check --profile <profile_name>
```

If it fails, the most common issue is they used a different Google account than the one with NotebookLM access. Suggest they re-run `nlm login --profile <profile_name>` and pick the right account.

### Step 9 — Pick a base folder

Tell the user:

> Last thing. The skill keeps a small tracking file for each notebook so it knows what's already been added (avoids double-adding the same PDF, etc.). Where do you want those tracking folders to live?
>
> I suggest `~/Documents/NotebookLM` if you don't have a preference. (The `~` means your home folder.)

Default to `~/Documents/NotebookLM` if they're unsure.

### Step 10 — Save state and finish

Run:

```bash
bash ~/.claude/skills/notebooklm/scripts/setup.sh save-state <profile_name> <base_folder>
```

Then tell the user:

> All set. Try one of these to get started:
>
> - "Set up a new notebook called Cooking with these PDFs: ..."
> - "Add this YouTube channel to my Cooking notebook: @SeriousEats"
> - "What notebooks do I have?"

Then return to their original request (if they had one) or wait for their next instruction.

---

# Normal operation (after setup)

## Intents

Map the user's request to one of these. Detect from phrasing.

| Intent | Trigger phrasing |
|---|---|
| **create** | "set up a new notebook for X", "make a notebook from Y", "create a NotebookLM..." |
| **add** | "add this {PDF/URL/text/channel/Drive doc} to my X notebook", "ingest Y into X" |
| **remove** | "remove the source about X", "delete Y from notebook Z" |
| **list** | "what's in my X notebook?", "list sources for X", "list my notebooks" |
| **rename** | "rename my X notebook to Y" |

If ambiguous, ask. Mixed sources in a single request (e.g., "create a notebook with these PDFs and YouTube channels") is still one create intent — the workflow handles mixed source types in one shot.

## Source types

Auto-detect from the input, then confirm with the user before acting.

| User input shape | Detected as | Adapter | Add mode |
|---|---|---|---|
| `@StumpyNubs`, `youtube.com/@X`, `youtube.com/@X/videos` | youtube-channel | `fetchers/youtube_channel.sh` | `youtube` |
| `youtube.com/watch?v=...`, `youtu.be/...` | youtube-video | (none — pass URL directly via url.sh) | `youtube` |
| Any other `https://` URL | url | `fetchers/url.sh` | `url` |
| `docs.google.com/.../d/<id>`, `drive.google.com/file/d/<id>` | gdrive-file | `fetchers/gdrive_file.sh` | `drive` |
| Absolute file path (PDF, txt, md, docx) | local-file | `fetchers/local_file.sh` | `file` |
| User says "paste this text:" or supplies title+content | text-paste | `fetchers/text.sh` | `text` |

A YouTube *playlist* URL is neither channel nor single video. Ask the user how they want it handled.

## Confirmation summary (before any mutation)

Before running anything that changes state, show a confirmation summary:

```
I'll <create | add to existing> notebook "<name>" with N sources:
  - YouTube channel @StumpyNubs (latest 100 videos)
  - 1 PDF: /path/to/Flexner.pdf
  - 2 web URLs
OK to proceed?
```

This is the last reversible checkpoint. After confirmation, the bulk add starts and each source costs ~1-3 sec.

## Workflow: create

Inputs:
- **Notebook name** (required)
- **Sources** (required, mixed types allowed)
- **For each youtube-channel source**: backfill count (default 100), short slug for ledger (e.g., `stumpy`)

Profile and base folder come from `~/.config/claude-notebooklm/state.json`.

### 1. Preflight

```bash
bash ~/.claude/skills/notebooklm/scripts/preflight.sh
```

Bails with a remediation message if `nlm` or `yt-dlp` isn't installed/authenticated. Surface verbatim and stop.

### 2. Create the notebook

```bash
nlm notebook create "<name>" --profile <profile>
```

Capture the notebook ID from `ID: <uuid>` in the output. Pass it everywhere downstream.

### 3. Scaffold the local tracking folder

```bash
FOLDER="<base_folder>/<name>"
bash ~/.claude/skills/notebooklm/scripts/scaffold.sh \
  "$FOLDER" "<name>" "<notebook_id>" "<profile>"
```

Read `<base_folder>` from the state file with `setup.sh state`.

### 4. Per source group: fetch → manifest → bulk_add

For each source group (one group per source-type), run the fetcher, then bulk_add.

**YouTube channel:**
```bash
bash ~/.claude/skills/notebooklm/scripts/fetchers/youtube_channel.sh \
  "<handle_or_url>" <count> "$FOLDER/<slug>_videos.tsv"

bash ~/.claude/skills/notebooklm/scripts/bulk_add.sh \
  "<notebook_id>" "<profile>" "<slug>" \
  "$FOLDER/<slug>_videos.tsv" \
  "$FOLDER/ledger.tsv" "$FOLDER/failures.tsv" youtube
```

**Single YouTube videos / generic URLs:**
```bash
bash ~/.claude/skills/notebooklm/scripts/fetchers/url.sh \
  "$FOLDER/urls.tsv" <url1> <url2> ...

# add_mode is `youtube` if all URLs are youtube.com/watch, else `url`
bash ~/.claude/skills/notebooklm/scripts/bulk_add.sh \
  "<notebook_id>" "<profile>" "manual" \
  "$FOLDER/urls.tsv" "$FOLDER/ledger.tsv" "$FOLDER/failures.tsv" url
```

**Local files:**
```bash
bash ~/.claude/skills/notebooklm/scripts/fetchers/local_file.sh \
  "$FOLDER" "$FOLDER/files.tsv" /path/to/file1.pdf /path/to/file2.txt

bash ~/.claude/skills/notebooklm/scripts/bulk_add.sh \
  "<notebook_id>" "<profile>" "files" \
  "$FOLDER/files.tsv" "$FOLDER/ledger.tsv" "$FOLDER/failures.tsv" file
```

**Pasted text:**
```bash
bash ~/.claude/skills/notebooklm/scripts/fetchers/text.sh \
  "$FOLDER" "$FOLDER/text.tsv" "<title>" "<content>"

bash ~/.claude/skills/notebooklm/scripts/bulk_add.sh \
  "<notebook_id>" "<profile>" "text" \
  "$FOLDER/text.tsv" "$FOLDER/ledger.tsv" "$FOLDER/failures.tsv" text
```

**Google Drive docs:**
```bash
bash ~/.claude/skills/notebooklm/scripts/fetchers/gdrive_file.sh \
  "$FOLDER/drive.tsv" <url_or_id1> <url_or_id2> ...

bash ~/.claude/skills/notebooklm/scripts/bulk_add.sh \
  "<notebook_id>" "<profile>" "drive" \
  "$FOLDER/drive.tsv" "$FOLDER/ledger.tsv" "$FOLDER/failures.tsv" drive
```

Run source groups sequentially, not in parallel. Each source costs ~1-3 sec. For long backfills (>50 sources), use `run_in_background=true` and poll `wc -l "$FOLDER/ledger.tsv"` to track progress.

### 5. Verify

```bash
nlm notebook list --profile <profile> | grep -A1 <notebook_id>
```

Source count should roughly match `wc -l ledger.tsv` minus 1 (header). Glance at `failures.tsv` and surface the count to the user (copyright-blocked or no-transcript YouTube videos commonly fail).

## Workflow: add (modify existing)

Inputs:
- **Notebook name or ID** (required)
- **Sources to add** (required)

### 1. Discover (resolves notebook + auto-scaffolds folder if needed)

```bash
eval "$(bash ~/.claude/skills/notebooklm/scripts/discover.sh "<name_or_id>")"
# sets NOTEBOOK_ID, NOTEBOOK_NAME, NOTEBOOK_FOLDER, IS_FRESH_SCAFFOLD
```

If the notebook predates this skill (no local folder), discover scaffolds one and snapshots existing sources into `ledger.tsv` so future ops are idempotent.

Errors with exit 3 (no match) or 4 (ambiguous match). Surface the error and ask the user to disambiguate.

### 2. Confirm + bulk add

Same per-source-type fetcher + bulk_add sequence as the create workflow (step 4 above). Reuse `$NOTEBOOK_ID` and `$NOTEBOOK_FOLDER` from discover.

## Workflow: remove

```bash
eval "$(bash ~/.claude/skills/notebooklm/scripts/discover.sh "<name>")"

bash ~/.claude/skills/notebooklm/scripts/remove_source.sh \
  "$NOTEBOOK_ID" "<profile>" "$NOTEBOOK_FOLDER/ledger.tsv" \
  --by-title "<substring>"
# OR --by-id <source_id> OR --by-canonical <canonical_id>
```

Read `<profile>` from `setup.sh state`.

If `--by-title` matches >1 source, the script lists them and exits without deleting. Show the list to the user and ask which to delete.

## Workflow: list

For listing notebooks:
```bash
nlm notebook list --profile <profile>
```

For listing sources in one notebook:
```bash
eval "$(bash ~/.claude/skills/notebooklm/scripts/discover.sh "<name>")"
nlm source list "$NOTEBOOK_ID" --profile <profile>
```

Or read the local ledger for a source-typed view:
```bash
column -t -s $'\t' "$NOTEBOOK_FOLDER/ledger.tsv" | head -50
```

## Workflow: rename

```bash
eval "$(bash ~/.claude/skills/notebooklm/scripts/discover.sh "<old_name>")"
bash ~/.claude/skills/notebooklm/scripts/rename_notebook.sh \
  "$NOTEBOOK_ID" "<new_title>" "<profile>" "$NOTEBOOK_FOLDER"
```

Renames on NotebookLM AND moves the local folder.

## Hard-won conventions

- **1-second sleep between adds.** `bulk_add.sh` already does this. Don't try to parallelize. NotebookLM has no published rate limit; the sleep keeps us under any reasonable threshold.
- **Output parsing is brittle.** Scripts grep for `✓ Added source:` and `Source ID:` literal strings. If the `nlm` CLI changes those strings, parsing breaks. Watch on `nlm` upgrades.
- **Don't extract cookies.** If MCP and CLI auth get out of sync, restart the MCP. Never extract `~/.notebooklm-mcp-cli/profiles/<profile>/cookies.json`. Cookie files are credentials.
- **NotebookLM rejects some videos.** Copyright-blocked, music-only, or no-transcript videos fail to ingest. `bulk_add.sh` logs them to `failures.tsv` and continues. After a backfill, mention the failure count.
- **Idempotency by ledger.** `bulk_add.sh` checks the ledger's canonical_id before each add. Re-running a partial backfill is safe.
- **Source cap.** NotebookLM Pro caps notebooks at ~300 sources. `bulk_add.sh` warns at 250 and refuses past 290 unless `NOTEBOOK_LM_FORCE_PAST_CAP=1` is set.
- **Modify-existing without local folder.** `discover.sh` handles this automatically: it scaffolds the folder and snapshots existing sources into the ledger. The user never has to "register" a notebook.

## Files in this skill

- `SKILL.md` — this file
- `scripts/setup.sh` — first-run state machine (check, save-state, state, ensure-folder)
- `scripts/preflight.sh` — dependency + auth check
- `scripts/scaffold.sh` — per-notebook tracking folder
- `scripts/bulk_add.sh` — source-agnostic add loop with rate limit, idempotency, cap warning
- `scripts/discover.sh` — resolve notebook by name + auto-scaffold + snapshot existing sources
- `scripts/remove_source.sh` — delete sources by id, canonical_id, or title
- `scripts/rename_notebook.sh` — rename on NotebookLM + move local folder
- `scripts/fetchers/youtube_channel.sh` — `@handle` → manifest of N video IDs
- `scripts/fetchers/url.sh` — URL list → deduped manifest
- `scripts/fetchers/local_file.sh` — file paths → copy to `sources/` + manifest
- `scripts/fetchers/text.sh` — title + content → write to `texts/` + manifest
- `scripts/fetchers/gdrive_file.sh` — Drive URLs/IDs → normalized manifest

## When NOT to use this skill

- **Generating Studio content** (audio summaries, video overviews, slides, reports, quizzes, flashcards, mind maps, infographics). Use the `nlm audio create` / `video create` / `report create` commands directly.
- **Querying a notebook.** `nlm notebook query <id> "question"` is a one-liner. Don't drag the skill in for that.
- **Cross-notebook query.** `nlm cross query` is a separate command and not in this skill's scope yet.
