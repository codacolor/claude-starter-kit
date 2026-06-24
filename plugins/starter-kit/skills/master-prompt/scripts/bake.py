#!/usr/bin/env python3
"""
Bake Master Prompt — Extract master prompt from CLAUDE.md and export to Desktop.

Reads the content between <!-- MASTER_PROMPT_START --> and <!-- MASTER_PROMPT_END -->
markers in ~/.claude/CLAUDE.md and writes a clean copy to ~/Desktop/Master_Prompt_Baked.txt.
"""

import os
import sys
from pathlib import Path
from datetime import datetime

CLAUDE_MD_PATH = Path(os.path.expanduser("~/.claude/CLAUDE.md"))
OUTPUT_PATH = Path(os.path.expanduser("~/Desktop/Master_Prompt_Baked.txt"))

START_MARKER = "<!-- MASTER_PROMPT_START -->"
END_MARKER = "<!-- MASTER_PROMPT_END -->"


def extract_master_prompt() -> str | None:
    """Extract master prompt content from CLAUDE.md."""
    if not CLAUDE_MD_PATH.exists():
        print(f"Error: {CLAUDE_MD_PATH} not found")
        return None

    content = CLAUDE_MD_PATH.read_text()

    start_idx = content.find(START_MARKER)
    end_idx = content.find(END_MARKER)

    if start_idx == -1 or end_idx == -1:
        print("Error: Master prompt markers not found in CLAUDE.md")
        return None

    # Extract content between markers (excluding the markers themselves)
    prompt = content[start_idx + len(START_MARKER):end_idx].strip()
    return prompt


def bake():
    """Extract master prompt and write to Desktop."""
    prompt = extract_master_prompt()
    if not prompt:
        return False

    # Build output
    output = f"""# Master Prompt (Exported)
# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}
# Source: ~/.claude/CLAUDE.md
#
# Paste this into:
#   - Claude Desktop App → Settings → Profile → Custom Instructions
#   - OpenAI Codex CLI → save as ~/.codex/AGENTS.md (auto-loaded each session)
#   - Cursor → Settings → Rules for AI
#   - Windsurf → Settings → Custom Instructions
#   - Any other AI tool that accepts system instructions
#
# Note: The consumer ChatGPT app's Custom Instructions field is too short for a
# full Master Prompt — use Codex CLI for OpenAI instead.
#
# Full per-tool walkthrough: https://github.com/codacolor/master-prompt#using-it-with-other-ai-tools

{prompt}
"""

    OUTPUT_PATH.write_text(output)
    print(f"Exported to: {OUTPUT_PATH}")

    # Open the file
    os.system(f'open "{OUTPUT_PATH}"')
    return True


if __name__ == "__main__":
    success = bake()
    sys.exit(0 if success else 1)
