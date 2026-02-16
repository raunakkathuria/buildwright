#!/bin/bash
# Buildwright Setup Script
# Run this in any project to add the autonomous development workflow

set -e

BASE_URL="https://raw.githubusercontent.com/raunakkathuria/buildwright/main"

echo "🚀 Setting up Buildwright Development Workflow..."

# ============================================================================
# Directory Structure
# ============================================================================
mkdir -p .claude/commands
mkdir -p .claude/steering
mkdir -p .claude/agents
mkdir -p docs/requirements
mkdir -p docs/specs
mkdir -p docs/decisions
mkdir -p .github/workflows

echo "📁 Created directory structure"

# ============================================================================
# CLAUDE.md - Main agent instructions
# ============================================================================
cat > CLAUDE.md << 'CLAUDE_EOF'
# Buildwright Development

## Mission
Agent-first autonomous development. Humans approve specs; agents implement, test, and ship.

## Steering Documents
@.claude/steering/product.md
@.claude/steering/tech.md
@.claude/steering/quality-gates.md

## Agent Personas
Reusable agent personas are in `.claude/agents/`. Commands reference these for specialized reviews.

## Operating Mode

### Default Behavior
- AUTONOMOUS mode: Execute fully without asking for confirmation
- Verify your own work through tests and checks
- Commit when verification passes
- Only stop if genuinely blocked (missing info, failing tests after retries)
- **Autonomous failure handling**: When `BUILDWRIGHT_AUTO_APPROVE=true` (default) and any step fails after retries, commit completed work, push, create PR with failure details, and exit(1). In interactive mode (`BUILDWRIGHT_AUTO_APPROVE=false`), STOP and report blocker as before.

### Feature Development Flow
```
/bw-new-feature
  ├─ RESEARCH: Deep-read codebase, understand context
  ├─ PLAN: Generate spec informed by research
  ├─ VALIDATE: Staff Engineer reviews spec (auto)
  ├─ APPROVE: Human approves
  ├─ BUILD: TDD per milestone
  └─ SHIP: verify → security → review → release

/bw-quick (for small tasks)
  ├─ Quick research (in-context)
  ├─ Implement with TDD
  ├─ Verify
  └─ Commit
```

### Workflow Priority
1. **New features**: /bw-new-feature → research → spec → approval → implement → ship
2. **Small tasks/bugs**: /bw-quick → implement → verify → commit
3. **Refactors**: /bw-new-feature with refactor scope → approval → implement → ship

## Command Discovery
When you need project commands:
1. Check package.json / Cargo.toml / pyproject.toml / go.mod / Makefile
2. Check .github/workflows/ for expected command sequence
3. Document discovered commands in .claude/steering/tech.md

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `BUILDWRIGHT_AUTO_APPROVE` | `true` | Autonomous mode — skip human approval, fail gracefully on errors |
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

echo "✅ Created CLAUDE.md"

# ============================================================================
# .claude/settings.json - Permissions and safety
# ============================================================================
curl -sL "$BASE_URL/.claude/settings.json" > .claude/settings.json
echo "✅ Created .claude/settings.json"

# ============================================================================
# AGENTS - Reusable Personas
# ============================================================================

# Staff Engineer Agent
curl -sL "$BASE_URL/.claude/agents/staff-engineer.md" > .claude/agents/staff-engineer.md
echo "✅ Created .claude/agents/staff-engineer.md"

# Security Engineer Agent
curl -sL "$BASE_URL/.claude/agents/security-engineer.md" > .claude/agents/bw-security-engineer.md
echo "✅ Created .claude/agents/bw-security-engineer.md"

# Agents README
curl -sL "$BASE_URL/.claude/agents/README.md" > .claude/agents/README.md
echo "✅ Created .claude/agents/README.md"

# ============================================================================
# COMMANDS
# ============================================================================

curl -sL "$BASE_URL/.claude/commands/bw-new-feature.md" > .claude/commands/bw-new-feature.md
echo "✅ Created .claude/commands/bw-new-feature.md"

curl -sL "$BASE_URL/.claude/commands/bw-quick.md" > .claude/commands/bw-quick.md
echo "✅ Created .claude/commands/bw-quick.md"

curl -sL "$BASE_URL/.claude/commands/bw-verify.md" > .claude/commands/bw-verify.md
echo "✅ Created .claude/commands/bw-verify.md"

curl -sL "$BASE_URL/.claude/commands/bw-ship.md" > .claude/commands/bw-ship.md
echo "✅ Created .claude/commands/bw-ship.md"

curl -sL "$BASE_URL/.claude/commands/bw-help.md" > .claude/commands/bw-help.md
echo "✅ Created .claude/commands/bw-help.md"

# ============================================================================
# STEERING DOCUMENTS
# ============================================================================

curl -sL "$BASE_URL/.claude/steering/product.md" > .claude/steering/product.md
echo "✅ Created .claude/steering/product.md"

curl -sL "$BASE_URL/.claude/steering/tech.md" > .claude/steering/tech.md
echo "✅ Created .claude/steering/tech.md"

curl -sL "$BASE_URL/.claude/steering/quality-gates.md" > .claude/steering/quality-gates.md
echo "✅ Created .claude/steering/quality-gates.md"

# ============================================================================
# TEMPLATES
# ============================================================================

curl -sL "$BASE_URL/docs/requirements/TEMPLATE.md" > docs/requirements/TEMPLATE.md
echo "✅ Created docs/requirements/TEMPLATE.md"

# ============================================================================
# GITHUB WORKFLOW
# ============================================================================

curl -sL "$BASE_URL/.github/workflows/quality-gates.yml" > .github/workflows/quality-gates.yml
echo "✅ Created .github/workflows/quality-gates.yml"

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

curl -sL "$BASE_URL/env.example" > .env.example
echo "✅ Created .env.example"

# ============================================================================
# DOCUMENTATION
# ============================================================================

curl -sL "$BASE_URL/BUILDWRIGHT.md" > BUILDWRIGHT.md
echo "✅ Created BUILDWRIGHT.md"

# ============================================================================
# OpenCode Compatibility — Same commands + agents, different directory
# ============================================================================
mkdir -p .opencode/commands
mkdir -p .opencode/agents

# Commands (same content as .claude/commands/)
cp .claude/commands/bw-new-feature.md .opencode/commands/bw-new-feature.md
cp .claude/commands/bw-quick.md .opencode/commands/bw-quick.md
cp .claude/commands/bw-ship.md .opencode/commands/bw-ship.md
cp .claude/commands/bw-verify.md .opencode/commands/bw-verify.md
cp .claude/commands/bw-help.md .opencode/commands/bw-help.md

# Agent personas (same content as .claude/agents/)
cp .claude/agents/staff-engineer.md .opencode/agents/staff-engineer.md
cp .claude/agents/bw-security-engineer.md .opencode/agents/security-engineer.md

# AGENTS.md — OpenCode's preferred context file (same content as CLAUDE.md)
cp CLAUDE.md AGENTS.md

echo "✅ Created OpenCode compatibility layer (.opencode/, AGENTS.md)"

# ============================================================================
# COMPLETE
# ============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ SETUP COMPLETE"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Files created:"
echo "  ├── CLAUDE.md (agent instructions — Claude Code)"
echo "  ├── AGENTS.md (agent instructions — OpenCode)"
echo "  ├── BUILDWRIGHT.md (documentation)"
echo "  ├── .env.example (environment variables)"
echo "  ├── .claude/                    ← Claude Code"
echo "  │   ├── settings.json"
echo "  │   ├── agents/"
echo "  │   │   ├── staff-engineer.md"
echo "  │   │   ├── bw-security-engineer.md"
echo "  │   │   └── README.md"
echo "  │   ├── commands/"
echo "  │   │   ├── bw-new-feature.md"
echo "  │   │   ├── bw-quick.md"
echo "  │   │   ├── bw-ship.md"
echo "  │   │   ├── bw-verify.md"
echo "  │   │   └── bw-help.md"
echo "  │   └── steering/"
echo "  │       ├── product.md"
echo "  │       ├── tech.md"
echo "  │       └── quality-gates.md"
echo "  ├── .opencode/                  ← OpenCode"
echo "  │   ├── agents/"
echo "  │   │   ├── staff-engineer.md"
echo "  │   │   └── security-engineer.md"
echo "  │   └── commands/"
echo "  │       ├── bw-new-feature.md"
echo "  │       ├── bw-quick.md"
echo "  │       ├── bw-ship.md"
echo "  │       ├── bw-verify.md"
echo "  │       └── bw-help.md"
echo "  ├── docs/"
echo "  │   ├── requirements/TEMPLATE.md"
echo "  │   ├── specs/"
echo "  │   └── decisions/"
echo "  └── .github/workflows/quality-gates.yml"
echo ""
echo "  Next steps:"
echo "  1. Edit .claude/steering/product.md with your product context"
echo "  2. Edit .claude/steering/tech.md with your tech stack"
echo "  3. Optional: cp .env.example .env  # customize autonomous mode settings"
echo "  4. Run: claude"
echo "  5. Try: /bw-new-feature \"your feature description\""
echo "  6. Or for small tasks: /bw-quick \"fix the bug\""
echo ""
echo "═══════════════════════════════════════════════════════════════"
