#!/bin/bash
# Buildwright Setup Script
# Run this in any project to add the autonomous development workflow
# Supports: Claude Code, OpenCode, OpenClaw
#
# Canonical config lives in .buildwright/ (tool-agnostic)
# Sync script generates .claude/ and .opencode/ from it

set -e

BASE_URL="https://raw.githubusercontent.com/raunakkathuria/buildwright/main"

echo "Setting up Buildwright Development Workflow..."

# ============================================================================
# Directory Structure — .buildwright/ is the canonical source
# ============================================================================
mkdir -p .buildwright/commands
mkdir -p .buildwright/steering
mkdir -p .buildwright/agents
mkdir -p .buildwright/claws
mkdir -p .buildwright/tasks
mkdir -p .claude           # For settings.json (Claude Code-specific)
mkdir -p docs/requirements
mkdir -p docs/specs
mkdir -p docs/decisions
mkdir -p .github/workflows
mkdir -p scripts

echo "  Created directory structure"

# ============================================================================
# CLAUDE.md - Main agent instructions (references .buildwright/)
# ============================================================================
cat > CLAUDE.md << 'CLAUDE_EOF'
# Buildwright Development

## Mission
Agent-first autonomous development. Humans approve specs; agents implement, test, and ship.

## Steering Documents
@.buildwright/steering/product.md
@.buildwright/steering/tech.md
@.buildwright/steering/quality-gates.md
@.buildwright/steering/naming-conventions.md

## Agents & Claws
- Agent personas in `.buildwright/agents/` -- Staff Engineer, Security Engineer, Architect
- Domain-specialist claws in `.buildwright/claws/` -- Frontend, Backend, Database (+ TEMPLATE for custom)
- Use `/bw-claw` for cross-domain features that need the Claw Architecture

## Operating Mode

### Default Behavior
- AUTONOMOUS mode: Execute fully without asking for confirmation
- Verify your own work through tests and checks
- Commit when verification passes
- Only stop if genuinely blocked (missing info, failing tests after retries)
- **Autonomous failure handling**: When `BUILDWRIGHT_AUTO_APPROVE=true` (default) and any step fails after retries, commit completed work, push, create PR with failure details, and exit(1). In interactive mode (`BUILDWRIGHT_AUTO_APPROVE=false`), STOP and report blocker as before.

### Workflow Priority
1. **New features (single domain)**: /bw-new-feature -> research -> spec -> approval -> implement -> ship
2. **Cross-domain features**: /bw-claw -> architect decomposes -> claws execute -> integrate -> ship
3. **Small tasks/bugs**: /bw-quick -> implement -> verify -> commit
4. **Ship existing work**: /bw-ship -> verify -> security -> review -> push -> PR
5. **Quick quality check**: /bw-verify -> typecheck, lint, test, build

## Command Discovery
When you need project commands:
1. Check package.json / Cargo.toml / pyproject.toml / go.mod / Makefile
2. Check .github/workflows/ for expected command sequence
3. Document discovered commands in .buildwright/steering/tech.md

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `BUILDWRIGHT_AUTO_APPROVE` | `true` | Autonomous mode -- skip human approval, fail gracefully on errors |
| `BUILDWRIGHT_AGENT_RETRIES` | `2` | Number of verify retries before giving up |

## Design Principles (ALWAYS APPLY)

1. **KISS (Keep It Simple, Stupid)**
   - Prefer simple solutions over clever ones
   - If it feels complex, step back and simplify
   - Code should be readable by a junior developer

2. **YAGNI (You Aren't Gonna Need It)**
   - Build only what's required NOW
   - No speculative features "for later"
   - Avoid abstractions until they're proven needed

3. **No Premature Optimization**
   - Make it work first, then make it fast (if needed)
   - Optimize only with profiling data
   - Readability > micro-optimizations

4. **Boring Technology**
   - Prefer proven, well-documented solutions
   - New tech only when it solves a real problem
   - Consider maintenance burden

5. **Fail Fast, Fail Loud**
   - Validate inputs at boundaries
   - Throw errors early with clear messages
   - No silent failures

## Code Standards
- Follow existing patterns in the codebase exactly
- Keep files under 500 lines; split proactively
- Write tests for all new functionality (TDD preferred)
- No `any` types in TypeScript
- Use Decimal/BigDecimal for financial calculations, NEVER floating point
- All user inputs must be validated

## Git Rules
- Atomic commits: only commit files you changed
- Conventional commits: feat:, fix:, refactor:, test:, docs:, chore:
- List each file explicitly in commit message
- Never edit .env files
- Never run destructive git operations without explicit instruction
- Multi-agent safety: NEVER use git stash (other agents may be working)

## Self-Improvement
When you discover a pattern, gotcha, or better approach:
- Add it below under "Learned Patterns"
- Keep entries concise (one line each)

## Learned Patterns
<!-- Agent adds entries here as it learns -->

CLAUDE_EOF

echo "  Created CLAUDE.md"

# ============================================================================
# .claude/settings.json - Claude Code permissions (stays in .claude/)
# ============================================================================
curl -sL "$BASE_URL/.claude/settings.json" > .claude/settings.json
echo "  Created .claude/settings.json"

# ============================================================================
# AGENTS — Download to .buildwright/ (canonical source)
# ============================================================================

curl -sL "$BASE_URL/.buildwright/agents/staff-engineer.md" > .buildwright/agents/staff-engineer.md
curl -sL "$BASE_URL/.buildwright/agents/security-engineer.md" > .buildwright/agents/security-engineer.md
curl -sL "$BASE_URL/.buildwright/agents/architect.md" > .buildwright/agents/architect.md
curl -sL "$BASE_URL/.buildwright/agents/README.md" > .buildwright/agents/README.md
echo "  Created agent personas (staff-engineer, security-engineer, architect)"

# ============================================================================
# CLAWS — Domain Specialist Templates
# ============================================================================

curl -sL "$BASE_URL/.buildwright/claws/README.md" > .buildwright/claws/README.md
curl -sL "$BASE_URL/.buildwright/claws/TEMPLATE.md" > .buildwright/claws/TEMPLATE.md
curl -sL "$BASE_URL/.buildwright/claws/frontend.md" > .buildwright/claws/frontend.md
curl -sL "$BASE_URL/.buildwright/claws/backend.md" > .buildwright/claws/backend.md
curl -sL "$BASE_URL/.buildwright/claws/database.md" > .buildwright/claws/database.md
curl -sL "$BASE_URL/.buildwright/claws/devops.md" > .buildwright/claws/devops.md
echo "  Created claw templates (frontend, backend, database, devops)"

# ============================================================================
# COMMANDS
# ============================================================================

curl -sL "$BASE_URL/.buildwright/commands/bw-new-feature.md" > .buildwright/commands/bw-new-feature.md
curl -sL "$BASE_URL/.buildwright/commands/bw-claw.md" > .buildwright/commands/bw-claw.md
curl -sL "$BASE_URL/.buildwright/commands/bw-quick.md" > .buildwright/commands/bw-quick.md
curl -sL "$BASE_URL/.buildwright/commands/bw-verify.md" > .buildwright/commands/bw-verify.md
curl -sL "$BASE_URL/.buildwright/commands/bw-ship.md" > .buildwright/commands/bw-ship.md
curl -sL "$BASE_URL/.buildwright/commands/bw-help.md" > .buildwright/commands/bw-help.md
echo "  Created commands (bw-new-feature, bw-claw, bw-quick, bw-ship, bw-verify, bw-help)"

# ============================================================================
# STEERING DOCUMENTS
# ============================================================================

curl -sL "$BASE_URL/.buildwright/steering/product.md" > .buildwright/steering/product.md
curl -sL "$BASE_URL/.buildwright/steering/tech.md" > .buildwright/steering/tech.md
curl -sL "$BASE_URL/.buildwright/steering/quality-gates.md" > .buildwright/steering/quality-gates.md
curl -sL "$BASE_URL/.buildwright/steering/naming-conventions.md" > .buildwright/steering/naming-conventions.md
echo "  Created steering documents (product, tech, quality-gates, naming-conventions)"

# ============================================================================
# TEMPLATES
# ============================================================================

curl -sL "$BASE_URL/docs/requirements/TEMPLATE.md" > docs/requirements/TEMPLATE.md
curl -sL "$BASE_URL/.buildwright/tasks/TEMPLATE.md" > .buildwright/tasks/TEMPLATE.md
echo "  Created templates"

# ============================================================================
# SCRIPTS
# ============================================================================

curl -sL "$BASE_URL/scripts/sync-agents.sh" > scripts/sync-agents.sh
curl -sL "$BASE_URL/scripts/validate-skill.sh" > scripts/validate-skill.sh
chmod +x scripts/sync-agents.sh scripts/validate-skill.sh
echo "  Created scripts (sync-agents, validate-skill)"

# ============================================================================
# GITHUB WORKFLOW
# ============================================================================

curl -sL "$BASE_URL/.github/workflows/quality-gates.yml" > .github/workflows/quality-gates.yml
echo "  Created .github/workflows/quality-gates.yml"

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

curl -sL "$BASE_URL/env.example" > .env.example
echo "  Created .env.example"

# ============================================================================
# DOCUMENTATION
# ============================================================================

curl -sL "$BASE_URL/BUILDWRIGHT.md" > BUILDWRIGHT.md
echo "  Created BUILDWRIGHT.md"

# ============================================================================
# Sync: .buildwright/ → .claude/ + .opencode/ + AGENTS.md
# ============================================================================

scripts/sync-agents.sh
echo "  Synced tool-specific configs (.claude/, .opencode/, AGENTS.md)"

# ============================================================================
# COMPLETE
# ============================================================================

echo ""
echo "==============================================================="
echo "  SETUP COMPLETE"
echo "==============================================================="
echo ""
echo "  Canonical config:  .buildwright/   (edit this)"
echo "  Claude Code:       .claude/        (generated by sync)"
echo "  OpenCode:          .opencode/      (generated by sync)"
echo "  OpenClaw:          SKILL.md        (install via: make openclaw)"
echo ""
echo "  Next steps:"
echo "  1. Edit .buildwright/steering/product.md with your product context"
echo "  2. Edit .buildwright/steering/tech.md with your tech stack"
echo "  3. Optional: cp .env.example .env"
echo "  4. Start your agent tool and try:"
echo "     /bw-new-feature \"your feature description\""
echo "     /bw-claw \"cross-domain feature\""
echo "     /bw-quick \"fix the bug\""
echo ""
echo "  After editing .buildwright/, run: scripts/sync-agents.sh"
echo "==============================================================="
