#!/bin/bash
# Buildwright Setup Script
# Run this in any project to add the lightweight engineering workflow.
#
# Everything Buildwright owns lands under .buildwright/ (plus the AGENTS.md /
# CLAUDE.md instruction files). Existing project files are never overwritten.

set -e

BASE_URL="${BUILDWRIGHT_BASE_URL:-https://raw.githubusercontent.com/raunakkathuria/buildwright/main}"

echo "Setting up Buildwright..."

mkdir -p .buildwright/commands
mkdir -p .buildwright/framework
mkdir -p .buildwright/steering
mkdir -p .buildwright/agents
mkdir -p .buildwright/codebase
mkdir -p .buildwright/scripts/hooks
mkdir -p docs/specs

# Root instruction files — added only if absent, never overwritten.
[ -f AGENTS.md ] || curl -sL "$BASE_URL/AGENTS.md" > AGENTS.md
[ -f CLAUDE.md ] || curl -sL "$BASE_URL/CLAUDE.md" > CLAUDE.md
if [ ! -f .claude/settings.json ]; then
  mkdir -p .claude
  curl -sL "$BASE_URL/.claude/settings.json" > .claude/settings.json
fi

curl -sL "$BASE_URL/.buildwright/agents/staff-engineer.md" > .buildwright/agents/staff-engineer.md
curl -sL "$BASE_URL/.buildwright/agents/security-engineer.md" > .buildwright/agents/security-engineer.md
curl -sL "$BASE_URL/.buildwright/agents/README.md" > .buildwright/agents/README.md

curl -sL "$BASE_URL/.buildwright/commands/bw-work.md" > .buildwright/commands/bw-work.md
curl -sL "$BASE_URL/.buildwright/commands/bw-plan.md" > .buildwright/commands/bw-plan.md
curl -sL "$BASE_URL/.buildwright/commands/bw-verify.md" > .buildwright/commands/bw-verify.md
curl -sL "$BASE_URL/.buildwright/commands/bw-ship.md" > .buildwright/commands/bw-ship.md
curl -sL "$BASE_URL/.buildwright/commands/bw-analyse.md" > .buildwright/commands/bw-analyse.md

curl -sL "$BASE_URL/.buildwright/framework/autonomy.md" > .buildwright/framework/autonomy.md
curl -sL "$BASE_URL/.buildwright/framework/capability.md" > .buildwright/framework/capability.md
curl -sL "$BASE_URL/.buildwright/framework/findings.md" > .buildwright/framework/findings.md
curl -sL "$BASE_URL/.buildwright/framework/tasks-to-issues.md" > .buildwright/framework/tasks-to-issues.md

curl -sL "$BASE_URL/.buildwright/steering/philosophy.md" > .buildwright/steering/philosophy.md

curl -sL "$BASE_URL/.buildwright/scripts/sync-agents.sh" > .buildwright/scripts/sync-agents.sh
curl -sL "$BASE_URL/.buildwright/scripts/validate-docs.sh" > .buildwright/scripts/validate-docs.sh
curl -sL "$BASE_URL/.buildwright/scripts/install-hooks.sh" > .buildwright/scripts/install-hooks.sh
curl -sL "$BASE_URL/.buildwright/scripts/hooks/pre-commit" > .buildwright/scripts/hooks/pre-commit
curl -sL "$BASE_URL/.buildwright/scripts/hooks/post-merge" > .buildwright/scripts/hooks/post-merge
curl -sL "$BASE_URL/.buildwright/scripts/hooks/post-checkout" > .buildwright/scripts/hooks/post-checkout
chmod +x .buildwright/scripts/*.sh .buildwright/scripts/hooks/*

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
