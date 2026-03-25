#!/bin/bash
# Sync agent configurations across Claude Code, OpenCode, Cursor, and OpenClaw
#
# Source of truth: .buildwright/ (tool-agnostic canonical config)
# Generates:
#   .claude/commands/        ← from .buildwright/commands/ (paths rewritten to .claude/)
#   .claude/agents/          ← from .buildwright/agents/
#   .claude/claws/           ← from .buildwright/claws/
#   .claude/steering/        ← from .buildwright/steering/
#   .claude/tasks/           ← from .buildwright/tasks/
#   .opencode/commands/      ← from .buildwright/commands/ (paths rewritten to .opencode/)
#   .opencode/agents/        ← from .buildwright/agents/
#   .opencode/claws/         ← from .buildwright/claws/
#   .opencode/steering/      ← from .buildwright/steering/
#   .cursor/rules/steering/  ← .mdc files with alwaysApply: true
#   .cursor/rules/commands/  ← .mdc files with alwaysApply: false
#   .cursor/rules/agents/    ← .mdc files with alwaysApply: false
#   .cursor/rules/claws/     ← .mdc files with alwaysApply: false
#   AGENTS.md                ← CLAUDE.md with OpenCode header prepended
#   dist/buildwright/        ← SKILL.md packaged for ClawHub
#
# Usage: scripts/sync-agents.sh [--check]
#   --check: Verify sync without modifying files (exit 1 if out of sync)

set -e

CHECK_ONLY=false
if [ "$1" = "--check" ]; then
  CHECK_ONLY=true
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# ============================================================================
# Helpers
# ============================================================================

# sync_dir SRC DST [REWRITE_FROM REWRITE_TO]
# Copies directory, optionally rewriting path references in .md files
sync_dir() {
  local src="$1"
  local dst="$2"
  local rewrite_from="${3:-}"
  local rewrite_to="${4:-}"

  if [ ! -d "$src" ]; then
    return
  fi

  if [ "$CHECK_ONLY" = true ]; then
    if [ ! -d "$dst" ]; then
      echo "MISSING: $dst (should be synced from $src)"
      SYNC_NEEDED=true
      return
    fi
    # Generate expected output to temp dir and compare
    local tmpdir
    tmpdir=$(mktemp -d)
    cp -R "$src/"* "$tmpdir/" 2>/dev/null || true
    if [ -n "$rewrite_from" ] && [ -n "$rewrite_to" ]; then
      find "$tmpdir" -name "*.md" -exec sed -i "s|$rewrite_from|$rewrite_to|g" {} + 2>/dev/null || true
    fi
    if ! diff -rq "$tmpdir" "$dst" > /dev/null 2>&1; then
      echo "OUT OF SYNC: $dst differs from $src"
      SYNC_NEEDED=true
    fi
    rm -rf "$tmpdir"
  else
    mkdir -p "$dst"
    rsync -a --delete "$src/" "$dst/" 2>/dev/null || (rm -rf "$dst"/* && cp -R "$src/"* "$dst/")
    # Rewrite path references for tool-specific copies
    if [ -n "$rewrite_from" ] && [ -n "$rewrite_to" ]; then
      find "$dst" -name "*.md" -exec sed -i "s|$rewrite_from|$rewrite_to|g" {} + 2>/dev/null || true
    fi
    echo "  synced $src → $dst"
  fi
}

# Global vars used by set_cursor_frontmatter / sync_cursor_dir
CURSOR_ALWAYS_APPLY=""
CURSOR_DESCRIPTION=""

# set_cursor_frontmatter PRESET FILENAME
# Sets CURSOR_ALWAYS_APPLY and CURSOR_DESCRIPTION globals for the given file.
set_cursor_frontmatter() {
  local preset="$1"
  local filename="$2"

  case "$preset" in
    steering|codebase) CURSOR_ALWAYS_APPLY="true" ;;
    *)                 CURSOR_ALWAYS_APPLY="false" ;;
  esac

  case "${preset}:${filename}" in
    steering:product)            CURSOR_DESCRIPTION="Buildwright product context: goals, features, user personas, business constraints" ;;
    steering:tech)               CURSOR_DESCRIPTION="Buildwright technical context: stack, commands, architecture patterns" ;;
    steering:quality-gates)      CURSOR_DESCRIPTION="Buildwright quality gates: automated checks that must pass before merge" ;;
    steering:naming-conventions) CURSOR_DESCRIPTION="Buildwright naming conventions: canonical field and endpoint registry" ;;
    codebase:STACK)              CURSOR_DESCRIPTION="Codebase tech stack: languages, runtime, frameworks, dependencies, integrations" ;;
    codebase:ARCHITECTURE)       CURSOR_DESCRIPTION="Codebase architecture: layers, data flow, entry points, directory structure" ;;
    codebase:CONVENTIONS)        CURSOR_DESCRIPTION="Codebase conventions: naming, code style, imports, error handling, testing patterns" ;;
    codebase:CONCERNS)           CURSOR_DESCRIPTION="Codebase concerns: tech debt, bugs, security risks, performance bottlenecks" ;;
    command:bw-new-feature)      CURSOR_DESCRIPTION="Buildwright bw-new-feature: full pipeline for new features with spec and TDD" ;;
    command:bw-claw)             CURSOR_DESCRIPTION="Buildwright bw-claw: multi-agent cross-domain feature development" ;;
    command:bw-quick)            CURSOR_DESCRIPTION="Buildwright bw-quick: fast path for bug fixes and small tasks" ;;
    command:bw-ship)             CURSOR_DESCRIPTION="Buildwright bw-ship: quality pipeline then commit, push, and PR" ;;
    command:bw-verify)           CURSOR_DESCRIPTION="Buildwright bw-verify: quick quality checks (typecheck, lint, test, build)" ;;
    command:bw-help)             CURSOR_DESCRIPTION="Buildwright bw-help: list all available Buildwright commands" ;;
    command:bw-analyse)          CURSOR_DESCRIPTION="Buildwright bw-analyse: analyse codebase, write structured docs to .buildwright/codebase/, update tech.md" ;;
    command:bw-worktree-start)   CURSOR_DESCRIPTION="Buildwright bw-worktree-start: set up isolated git worktree before implementation" ;;
    command:bw-worktree-finish)  CURSOR_DESCRIPTION="Buildwright bw-worktree-finish: complete development branch with merge, PR, keep, or discard + worktree cleanup" ;;
    command:bw-plan)             CURSOR_DESCRIPTION="Buildwright bw-plan: research a question, produce a written deliverable — no implementation" ;;
    agent:architect)             CURSOR_DESCRIPTION="Buildwright Architect agent persona" ;;
    agent:staff-engineer)        CURSOR_DESCRIPTION="Buildwright Staff Engineer agent persona" ;;
    agent:security-engineer)     CURSOR_DESCRIPTION="Buildwright Security Engineer agent persona" ;;
    claw:frontend)               CURSOR_DESCRIPTION="Buildwright Frontend domain specialist claw" ;;
    claw:backend)                CURSOR_DESCRIPTION="Buildwright Backend domain specialist claw" ;;
    claw:database)               CURSOR_DESCRIPTION="Buildwright Database domain specialist claw" ;;
    claw:devops)                 CURSOR_DESCRIPTION="Buildwright DevOps domain specialist claw" ;;
    *)                           CURSOR_DESCRIPTION="Buildwright ${preset}: ${filename}" ;;
  esac
}

# sync_cursor_dir SRC DST_SUBDIR PRESET
# Converts .md files in SRC to .mdc files in .cursor/rules/DST_SUBDIR,
# prepending YAML frontmatter and rewriting @.buildwright/ → @.cursor/rules/.
# Skips README and TEMPLATE files.
sync_cursor_dir() {
  local src="$1"
  local dst_subdir="$2"
  local preset="$3"
  local dst=".cursor/rules/$dst_subdir"

  if [ ! -d "$src" ]; then
    return
  fi

  if [ "$CHECK_ONLY" = false ]; then
    mkdir -p "$dst"
  fi

  for src_file in "$src"/*.md; do
    [ -f "$src_file" ] || continue
    local filename
    filename=$(basename "$src_file" .md)

    # Skip meta files — they're internal docs, not rules
    case "$filename" in
      README|TEMPLATE) continue ;;
    esac

    local dst_file="$dst/$filename.mdc"
    set_cursor_frontmatter "$preset" "$filename"

    if [ "$CHECK_ONLY" = true ]; then
      if [ ! -f "$dst_file" ]; then
        echo "MISSING: $dst_file"
        SYNC_NEEDED=true
      else
        local tmpfile
        tmpfile=$(mktemp)
        {
          printf '%s\n' "---"
          printf 'description: "%s"\n' "$CURSOR_DESCRIPTION"
          printf '%s\n' "globs: []"
          printf 'alwaysApply: %s\n' "$CURSOR_ALWAYS_APPLY"
          printf '%s\n' "---"
          sed 's|@\.buildwright/|@.cursor/rules/|g' "$src_file"
        } > "$tmpfile"
        if ! diff -q "$dst_file" "$tmpfile" > /dev/null 2>&1; then
          echo "OUT OF SYNC: $dst_file"
          SYNC_NEEDED=true
        fi
        rm -f "$tmpfile"
      fi
    else
      {
        printf '%s\n' "---"
        printf 'description: "%s"\n' "$CURSOR_DESCRIPTION"
        printf '%s\n' "globs: []"
        printf 'alwaysApply: %s\n' "$CURSOR_ALWAYS_APPLY"
        printf '%s\n' "---"
        sed 's|@\.buildwright/|@.cursor/rules/|g' "$src_file"
      } > "$dst_file"
    fi
  done

  if [ "$CHECK_ONLY" = false ]; then
    echo "  synced $src → $dst (*.mdc)"
  fi
}

# ============================================================================
# 1. .buildwright/ → .claude/ (rewrite .buildwright/ → .claude/)
# ============================================================================

if [ "$CHECK_ONLY" = false ]; then
  echo "Syncing agent configurations..."
  echo ""
fi

SYNC_NEEDED=false

sync_dir ".buildwright/commands"  ".claude/commands"  ".buildwright/" ".claude/"
sync_dir ".buildwright/agents"    ".claude/agents"    ".buildwright/" ".claude/"
sync_dir ".buildwright/claws"     ".claude/claws"     ".buildwright/" ".claude/"
sync_dir ".buildwright/steering"  ".claude/steering"
sync_dir ".buildwright/codebase"  ".claude/codebase"
sync_dir ".buildwright/tasks"     ".claude/tasks"

# ============================================================================
# 2. .buildwright/ → .opencode/ (rewrite .buildwright/ → .opencode/)
# ============================================================================

sync_dir ".buildwright/commands"  ".opencode/commands"  ".buildwright/" ".opencode/"
sync_dir ".buildwright/agents"    ".opencode/agents"    ".buildwright/" ".opencode/"
sync_dir ".buildwright/claws"     ".opencode/claws"     ".buildwright/" ".opencode/"
sync_dir ".buildwright/steering"  ".opencode/steering"
sync_dir ".buildwright/codebase"  ".opencode/codebase"

# ============================================================================
# 3. CLAUDE.md → AGENTS.md
# ============================================================================

generate_agents_md() {
  local target="$1"
  printf '%s\n' "---" \
    "# OpenCode agent instructions" \
    "# Auto-generated from CLAUDE.md — do not edit directly" \
    "# Run: scripts/sync-agents.sh to regenerate" \
    "---" \
    "" > "$target"
  cat CLAUDE.md >> "$target"
}

if [ "$CHECK_ONLY" = true ]; then
  if [ ! -f "AGENTS.md" ]; then
    echo "MISSING: AGENTS.md (should be generated from CLAUDE.md)"
    SYNC_NEEDED=true
  else
    TMPFILE=$(mktemp)
    generate_agents_md "$TMPFILE"
    if ! diff -q "AGENTS.md" "$TMPFILE" > /dev/null 2>&1; then
      echo "OUT OF SYNC: AGENTS.md differs from CLAUDE.md"
      SYNC_NEEDED=true
    fi
    rm -f "$TMPFILE"
  fi
else
  generate_agents_md "AGENTS.md"
  echo "  generated AGENTS.md from CLAUDE.md"
fi

# ============================================================================
# 4. .buildwright/ → .cursor/rules/ (convert to .mdc with frontmatter)
# ============================================================================

sync_cursor_dir ".buildwright/steering"  "steering"  "steering"
sync_cursor_dir ".buildwright/codebase"  "codebase"  "codebase"
sync_cursor_dir ".buildwright/commands"  "commands"  "command"
sync_cursor_dir ".buildwright/agents"    "agents"    "agent"
sync_cursor_dir ".buildwright/claws"     "claws"     "claw"

# ============================================================================
# 5. .buildwright/commands/ → skills/ (Codex CLI skill discovery)
# ============================================================================

if [ "$CHECK_ONLY" = false ]; then
  for file in .buildwright/commands/bw-*.md; do
    [ -f "$file" ] || continue
    name=$(basename "$file" .md)
    mkdir -p "skills/$name"
    cp "$file" "skills/$name/SKILL.md"
    echo "  synced $file → skills/$name/SKILL.md"
  done
fi

# ============================================================================
# 6. Package for ClawHub (dist/)
# ============================================================================

if [ "$CHECK_ONLY" = false ] && [ -f "SKILL.md" ]; then
  mkdir -p dist/buildwright
  cp SKILL.md dist/buildwright/
  echo "  packaged dist/buildwright/SKILL.md for ClawHub"
fi

# ============================================================================
# 7. README.md → cli/README.md (single source of truth for npm package page)
# ============================================================================

if [ "$CHECK_ONLY" = false ] && [ -f "README.md" ]; then
  cp README.md cli/README.md
  echo "  README.md → cli/README.md"
fi

# ============================================================================
# Result
# ============================================================================

if [ "$CHECK_ONLY" = true ]; then
  if [ "$SYNC_NEEDED" = true ]; then
    echo ""
    echo "Run 'scripts/sync-agents.sh' to fix."
    exit 1
  else
    echo "All synced."
    exit 0
  fi
else
  echo ""
  echo "Sync complete. Source of truth: .buildwright/"
  echo "  .buildwright/ → .claude/         (paths rewritten)"
  echo "  .buildwright/ → .opencode/       (paths rewritten)"
  echo "  .buildwright/ → .cursor/rules/   (.mdc with frontmatter)"
  echo "  CLAUDE.md     → AGENTS.md"
  echo "  SKILL.md      → dist/buildwright/SKILL.md"
  echo "  .buildwright/commands/ → skills/          (Codex CLI skill discovery)"
  echo "  README.md     → cli/README.md             (npm package page)"

  # Validate all commands are documented in SKILL.md and README.md
  if [ -f "scripts/validate-docs.sh" ]; then
    echo ""
    bash scripts/validate-docs.sh || true
  fi
fi
