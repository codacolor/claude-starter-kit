#!/usr/bin/env bash
# Claude Starter Kit — one-line setup.
# Usage:  curl -fsSL https://raw.githubusercontent.com/codacolor/claude-starter-kit/main/setup.sh | bash
set -euo pipefail

echo ""
echo "  Claude Starter Kit"
echo "  =================="
echo ""

if ! command -v claude >/dev/null 2>&1; then
  echo "  Claude Code isn't installed yet."
  echo ""
  echo "  Install it first:  npm install -g @anthropic-ai/claude-code"
  echo "  (Need Node.js? Get it at https://nodejs.org)"
  echo ""
  echo "  Then run this setup line again."
  exit 1
fi

echo "  Adding the starter kit marketplace..."
claude plugin marketplace add codacolor/claude-starter-kit

echo "  Installing the starter-kit plugin..."
claude plugin install starter-kit@claude-starter-kit

echo ""
echo "  Done. Now open Claude Code and type:"
echo ""
echo "      /onboard"
echo ""
echo "  That sets up your workspace. After that, try /master-prompt next."
echo ""
