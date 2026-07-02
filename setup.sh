#!/bin/bash
# Buildwright Setup Script
# Run this in any project to add the lightweight engineering workflow.
#
# Downloads the repo tarball once and copies .buildwright/ wholesale, so new
# shipped files are always included. Everything Buildwright owns lands under
# .buildwright/ (plus AGENTS.md / CLAUDE.md, added only if absent). Existing
# project files are never overwritten.

set -e

TARBALL_URL="${BUILDWRIGHT_TARBALL_URL:-https://api.github.com/repos/raunakkathuria/buildwright/tarball/main}"

if [ -d .buildwright ]; then
  echo "Buildwright is already installed here."
  echo "To update, run: npm install -g buildwright@latest && buildwright update"
  exit 0
fi

echo "Setting up Buildwright..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -sL "$TARBALL_URL" | tar xz -C "$TMP_DIR" --strip-components=1

if [ ! -d "$TMP_DIR/.buildwright" ]; then
  echo "Error: downloaded archive is missing .buildwright/ — aborting." >&2
  exit 1
fi

cp -R "$TMP_DIR/.buildwright" .buildwright
chmod +x .buildwright/scripts/*.sh .buildwright/scripts/hooks/*
mkdir -p docs/specs

# Root instruction files — added only if absent, never overwritten.
[ -f AGENTS.md ] || cp "$TMP_DIR/AGENTS.md" AGENTS.md
[ -f CLAUDE.md ] || cp "$TMP_DIR/CLAUDE.md" CLAUDE.md

# Keep generated dirs out of the project's git history (append-only, idempotent).
GITIGNORE_MARKER="# --- buildwright generated ---"
if ! grep -qsF "$GITIGNORE_MARKER" .gitignore; then
  [ -f .gitignore ] && [ -n "$(tail -c1 .gitignore)" ] && echo "" >> .gitignore
  cat >> .gitignore <<'EOF'
# --- buildwright generated ---
# Generated from .buildwright/ by the Buildwright sync — do not commit.
.claude/agents/
.claude/commands/
.claude/framework/
.claude/steering/
.claude/skills/
.claude/settings.local.json
.opencode/
.cursor/rules/
/skills/
EOF
fi

bash .buildwright/scripts/sync-agents.sh
bash .buildwright/scripts/install-hooks.sh

echo ""
echo "Buildwright is ready."
echo "Next steps:"
echo "  1. Run /bw-analyse for unfamiliar brownfield projects."
echo "  2. Run /bw-work \"your task\" to implement work."
echo "  3. Buildwright will create tech.md/product.md only when it has real project context."
