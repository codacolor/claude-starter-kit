# NotebookLM for Claude Code

A Claude Code skill that lets you build, modify, and manage Google NotebookLM notebooks by just talking to Claude. No clicking around the NotebookLM website to add sources one at a time.

## What This Does

Once installed, you can say things like:

- "Set up a new notebook called Cooking with these PDFs: ~/Downloads/Salt-Fat-Acid-Heat.pdf, ~/Downloads/On-Food.pdf"
- "Add the YouTube channel @SeriousEats to my Cooking notebook (latest 100 videos)"
- "Add this article to my Cooking notebook: https://www.seriouseats.com/the-food-lab"
- "Add this Google Doc to my Cooking notebook: https://docs.google.com/document/d/abc123/edit"
- "What's in my Cooking notebook?"
- "Remove the source about pasta from my Cooking notebook"
- "Rename my Cooking notebook to Recipes"

Claude figures out what kind of source you're adding (PDF, URL, YouTube channel, etc.), confirms with you before making changes, and handles the busy work of bulk-adding sources with rate limiting and duplicate detection.

## Source Types Supported

- **PDFs, text files, markdown, Word docs** (any file on your computer)
- **Web URLs** (articles, blog posts, public web pages)
- **YouTube channels** (backfill the latest N videos from a channel)
- **YouTube videos** (one-off video URLs)
- **Google Drive docs** (Docs, Sheets, files in your Drive)
- **Pasted text** (paste content directly and give it a title)

## Requirements

- A Mac running macOS
- [Claude Code](https://claude.com/claude-code) installed
- A Google account with [NotebookLM](https://notebooklm.google.com) access (free tier works; Pro gets you more sources per notebook)

The skill will install everything else for you on first run.

## Installation

One command in your Terminal:

```bash
git clone https://github.com/codacolor/claude-notebooklm.git ~/.claude/skills/notebooklm
```

That's it. Open Claude Code and type:

```
/notebooklm
```

Or just say something like "set up a new notebook for me." Claude will detect this is your first time and walk you through a 5-minute setup (installing the NotebookLM CLI, signing into your Google account, picking a folder for tracking files).

## What Gets Installed During First-Run Setup

| Tool | What it's for | How it gets installed |
|---|---|---|
| Homebrew | Mac package manager (you may already have it) | One-line installer from brew.sh |
| `uv` | Modern Python tool manager | `brew install uv` |
| `nlm` | Official NotebookLM command-line tool | `uv tool install notebooklm-mcp-cli` |
| `yt-dlp` | YouTube metadata fetcher | `brew install yt-dlp` |

You'll also do a one-time browser login to NotebookLM with your Google account. Claude walks you through every step.

## How Tracking Folders Work

For each NotebookLM notebook you create or modify with this skill, a small folder gets created on your computer (default location: `~/Documents/NotebookLM/`). Each folder contains:

- `ledger.tsv`. A record of every source ever added to that notebook. Used so the skill never double-adds the same PDF or video.
- `failures.tsv`. Sources that NotebookLM rejected (e.g., a copyright-blocked YouTube video).
- `sources/`. Copies of any local files you added to the notebook (so the folder is self-contained).
- `texts/`. Pasted-text snippets staged for upload.

You can ignore these folders entirely. They're just bookkeeping. If you delete one, the skill loses its memory of what's in that notebook, but it'll re-snapshot from NotebookLM the next time you modify the notebook.

## Examples

### Build a new notebook from PDFs

> Set up a new notebook called Woodworking with these PDFs:
> ~/Downloads/Hand-Tool-Joinery.pdf, ~/Downloads/Workbench-Design.pdf

Claude reads the request, asks for confirmation, runs the setup, and reports back when done.

### Add a YouTube channel backfill

> Add the YouTube channel @StumpyNubs to my Woodworking notebook (latest 100 videos)

Claude resolves the channel, fetches the latest 100 video IDs via `yt-dlp`, and adds each one to NotebookLM with a 1-second delay between adds.

### Mix source types in one shot

> Make a notebook called Climate with these:
> - The PDF at ~/Downloads/IPCC-AR6.pdf
> - The YouTube channel @ClimateAdam (50 videos)
> - The article https://www.nature.com/articles/d41586-024-00...
> - The Google Doc https://docs.google.com/document/d/abc123/edit

Claude detects each source type, shows you a confirmation summary, then runs them in sequence.

## Troubleshooting

**"PREFLIGHT FAIL: profile not authenticated"**
Run the login command yourself: `nlm login --profile default` (or whatever profile name you picked). A browser will open. Sign in.

**"PREFLIGHT FAIL: nlm CLI not installed"**
The first-run setup didn't complete. Re-run setup by typing `/notebooklm` in Claude Code, or install manually: `uv tool install notebooklm-mcp-cli`.

**Wrong Google account signed in**
You can have multiple profiles. Run `nlm login --profile <new_profile_name>` to add another. Then update the skill's saved profile by re-running the first-run setup, or edit `~/.config/claude-notebooklm/state.json` directly.

**Some YouTube videos failed to ingest**
This is normal. NotebookLM rejects copyright-blocked videos, music-only videos, and videos with no transcript available. The failure count is shown after each backfill, and details are saved to `failures.tsv` in the notebook's tracking folder.

**Notebook hit the source cap**
NotebookLM Pro caps notebooks at about 300 sources. The skill warns you at 250 and refuses past 290. If you really need to push past that, set `NOTEBOOK_LM_FORCE_PAST_CAP=1` before the operation.

## Privacy and Local State

Everything stays on your machine:

- Your NotebookLM cookies live in `~/.notebooklm-mcp-cli/profiles/<profile>/cookies.json` (managed by the `nlm` CLI, not by this skill).
- Tracking folders live in `~/Documents/NotebookLM/` (or wherever you picked during setup).
- Setup state lives in `~/.config/claude-notebooklm/state.json`.

This skill never sends your data anywhere. It just runs local commands and talks to NotebookLM through your browser-authenticated session.

## What's Not Included (Yet)

- **Auto-syncing** new YouTube videos or Drive docs daily. (Possible to add manually with launchd, but not part of this skill.)
- **Cross-notebook query** (`nlm cross query` is a separate command).
- **Generating Studio content** (audio overviews, slide decks, mind maps, etc.). Use `nlm audio create` / `video create` / `report create` directly.

## Updating

To get the latest version:

```bash
cd ~/.claude/skills/notebooklm && git pull
```

Your saved settings in `~/.config/claude-notebooklm/state.json` and your notebook tracking folders are not touched by updates.

## Credits

Built on top of [`notebooklm-mcp-cli`](https://pypi.org/project/notebooklm-mcp-cli/) (the `nlm` command-line tool). NotebookLM is a Google product.

## License

MIT
