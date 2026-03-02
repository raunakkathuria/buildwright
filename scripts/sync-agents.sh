#!/bin/bash
# Sync agent configurations across Claude Code, OpenCode, and OpenClaw
#
# Source of truth: .buildwright/ (tool-agnostic canonical config)
# Generates:
#   .claude/commands/    ← from .buildwright/commands/ (paths rewritten to .claude/)
#   .claude/agents/      ← from .buildwright/agents/
#   .claude/claws/       ← from .buildwright/claws/
#   .claude/steering/    ← from .buildwright/steering/
#   .claude/tasks/       ← from .buildwright/tasks/
#   .opencode/commands/  ← from .buildwright/commands/ (paths rewritten to .opencode/)
#   .opencode/agents/    ← from .buildwright/agents/
#   .opencode/claws/     ← from .buildwright/claws/
#   .opencode/steering/  ← from .buildwright/steering/
#   AGENTS.md            ← CLAUDE.md with OpenCode header prepended
#   dist/buildwright/    ← SKILL.md packaged for ClawHub
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
sync_dir ".buildwright/tasks"     ".claude/tasks"

# ============================================================================
# 2. .buildwright/ → .opencode/ (rewrite .buildwright/ → .opencode/)
# ============================================================================

sync_dir ".buildwright/commands"  ".opencode/commands"  ".buildwright/" ".opencode/"
sync_dir ".buildwright/agents"    ".opencode/agents"    ".buildwright/" ".opencode/"
sync_dir ".buildwright/claws"     ".opencode/claws"     ".buildwright/" ".opencode/"
sync_dir ".buildwright/steering"  ".opencode/steering"

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
# 4. Package for ClawHub (dist/)
# ============================================================================

if [ "$CHECK_ONLY" = false ] && [ -f "SKILL.md" ]; then
  mkdir -p dist/buildwright
  cp SKILL.md dist/buildwright/
  echo "  packaged dist/buildwright/SKILL.md for ClawHub"
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
  echo "  .buildwright/ → .claude/    (paths rewritten)"
  echo "  .buildwright/ → .opencode/  (paths rewritten)"
  echo "  CLAUDE.md     → AGENTS.md"
  echo "  SKILL.md      → dist/buildwright/SKILL.md"
fi
