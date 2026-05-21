#!/bin/bash
# Buildwright Setup Script
# Run this in any project to add the lightweight engineering workflow.

set -e

BASE_URL="https://raw.githubusercontent.com/raunakkathuria/buildwright/main"

echo "Setting up Buildwright..."

mkdir -p .buildwright/commands
mkdir -p .buildwright/steering
mkdir -p .buildwright/agents
mkdir -p .buildwright/codebase
mkdir -p .claude
mkdir -p docs/specs
mkdir -p .github/workflows
mkdir -p scripts/hooks

curl -sL "$BASE_URL/CLAUDE.md" > CLAUDE.md
curl -sL "$BASE_URL/.claude/settings.json" > .claude/settings.json

curl -sL "$BASE_URL/.buildwright/agents/staff-engineer.md" > .buildwright/agents/staff-engineer.md
curl -sL "$BASE_URL/.buildwright/agents/security-engineer.md" > .buildwright/agents/security-engineer.md
curl -sL "$BASE_URL/.buildwright/agents/README.md" > .buildwright/agents/README.md

curl -sL "$BASE_URL/.buildwright/commands/bw-work.md" > .buildwright/commands/bw-work.md
curl -sL "$BASE_URL/.buildwright/commands/bw-plan.md" > .buildwright/commands/bw-plan.md
curl -sL "$BASE_URL/.buildwright/commands/bw-verify.md" > .buildwright/commands/bw-verify.md
curl -sL "$BASE_URL/.buildwright/commands/bw-ship.md" > .buildwright/commands/bw-ship.md
curl -sL "$BASE_URL/.buildwright/commands/bw-analyse.md" > .buildwright/commands/bw-analyse.md

curl -sL "$BASE_URL/.buildwright/steering/philosophy.md" > .buildwright/steering/philosophy.md

curl -sL "$BASE_URL/scripts/sync-agents.sh" > scripts/sync-agents.sh
curl -sL "$BASE_URL/scripts/validate-skill.sh" > scripts/validate-skill.sh
curl -sL "$BASE_URL/scripts/validate-docs.sh" > scripts/validate-docs.sh
curl -sL "$BASE_URL/scripts/install-hooks.sh" > scripts/install-hooks.sh
curl -sL "$BASE_URL/scripts/hooks/pre-commit" > scripts/hooks/pre-commit
curl -sL "$BASE_URL/scripts/hooks/post-merge" > scripts/hooks/post-merge
curl -sL "$BASE_URL/scripts/hooks/post-checkout" > scripts/hooks/post-checkout
chmod +x scripts/*.sh scripts/hooks/*

curl -sL "$BASE_URL/Makefile" > Makefile
curl -sL "$BASE_URL/BUILDWRIGHT.md" > BUILDWRIGHT.md
curl -sL "$BASE_URL/README.md" > README.md
curl -sL "$BASE_URL/.env.example" > .env.example
curl -sL "$BASE_URL/.gitignore" > .gitignore

make sync

echo ""
echo "Buildwright is ready."
echo "Next steps:"
echo "  1. Run /bw-analyse for unfamiliar brownfield projects."
echo "  2. Run /bw-work \"your task\" to implement work."
echo "  3. Buildwright will create tech.md/product.md only when it has real project context."
