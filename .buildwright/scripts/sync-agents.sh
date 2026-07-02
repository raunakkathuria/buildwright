#!/bin/bash
# Sync agent configurations across Claude Code, OpenCode, Cursor, and OpenClaw
#
# Source of truth: .buildwright/ (tool-agnostic canonical config)
# Generates:
#   .claude/commands/        ← from .buildwright/commands/ (paths rewritten to .claude/)
#   .claude/agents/          ← from .buildwright/agents/
#   .claude/steering/        ← from .buildwright/steering/
#   .opencode/commands/      ← from .buildwright/commands/ (paths rewritten to .opencode/)
#   .opencode/agents/        ← from .buildwright/agents/
#   .opencode/steering/      ← from .buildwright/steering/
#   .cursor/rules/steering/  ← .mdc files with alwaysApply: true
#   .cursor/rules/commands/  ← .mdc files with alwaysApply: false
#   .cursor/rules/agents/    ← .mdc files with alwaysApply: false
#   dist/buildwright/        ← SKILL.md packaged for ClawHub
#
# Note: AGENTS.md (canonical, committed) and CLAUDE.md (pointer stub) are NOT
# generated — they are hand-maintained root files.
#
# Usage: .buildwright/scripts/sync-agents.sh [--check]
#   --check: Verify sync without modifying files (exit 1 if out of sync)

set -e

CHECK_ONLY=false
if [ "$1" = "--check" ]; then
  CHECK_ONLY=true
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || { cd "$SCRIPT_DIR/../.." && pwd; })"
cd "$ROOT_DIR"

# ============================================================================
# Helpers
# ============================================================================

sed_inplace() {
  local expression="$1"
  local file="$2"

  if sed --version >/dev/null 2>&1; then
    sed -i -e "$expression" "$file"
  else
    sed -i '' -e "$expression" "$file"
  fi
}

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
      # Only rewrite @@.buildwright/ (read instructions) → tool-specific path
      # Bare .buildwright/ (write/canonical instructions) stays untouched
      while IFS= read -r file; do
        sed_inplace "s|@@${rewrite_from}|${rewrite_to}|g" "$file"
      done < <(find "$tmpdir" -name "*.md" -type f)
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
    # @@.buildwright/ = "resolve to tool-specific dir" → gets rewritten
    # Bare .buildwright/ = "canonical path" → stays untouched
    if [ -n "$rewrite_from" ] && [ -n "$rewrite_to" ]; then
      while IFS= read -r file; do
        sed_inplace "s|@@${rewrite_from}|${rewrite_to}|g" "$file"
      done < <(find "$dst" -name "*.md" -type f)
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
  local base_filename
  base_filename=$(basename "$filename")

  case "$preset" in
    steering|codebase|framework) CURSOR_ALWAYS_APPLY="true" ;;
    *)                           CURSOR_ALWAYS_APPLY="false" ;;
  esac

  case "${preset}:${base_filename}" in
    steering:product)            CURSOR_DESCRIPTION="Buildwright product context: goals, features, user personas, business constraints" ;;
    steering:tech)               CURSOR_DESCRIPTION="Buildwright technical context: stack, commands, architecture patterns" ;;
    steering:philosophy)         CURSOR_DESCRIPTION="Buildwright engineering philosophy: KISS, YAGNI, TDD, docs discipline" ;;
    framework:autonomy)          CURSOR_DESCRIPTION="Buildwright autonomy behaviour: proceed/pause/stop, auto-continue, context-inferred failure handling" ;;
    framework:capability)        CURSOR_DESCRIPTION="Buildwright host capabilities: prefer native plan/file-write/tasks/subagents/hooks with fallbacks" ;;
    framework:findings)          CURSOR_DESCRIPTION="Buildwright findings convention: report-upstream and before-production deferrals" ;;
    framework:tasks-to-issues)   CURSOR_DESCRIPTION="Buildwright tasks-to-issues convention: plan breakdown to tracked forge issues (parent + child-per-unit, stable IDs, idempotent, remote-guarded)" ;;
    codebase:STACK)              CURSOR_DESCRIPTION="Codebase tech stack: languages, runtime, frameworks, dependencies, integrations" ;;
    codebase:ARCHITECTURE)       CURSOR_DESCRIPTION="Codebase architecture: layers, data flow, entry points, directory structure" ;;
    codebase:CONVENTIONS)        CURSOR_DESCRIPTION="Codebase conventions: naming, code style, imports, error handling, testing patterns" ;;
    codebase:CONCERNS)           CURSOR_DESCRIPTION="Codebase concerns: tech debt, bugs, security risks, performance bottlenecks" ;;
    command:bw-work)             CURSOR_DESCRIPTION="Buildwright bw-work: implement bug fixes, refactors, and features" ;;
    command:bw-ship)             CURSOR_DESCRIPTION="Buildwright bw-ship: quality pipeline then commit, push, and PR" ;;
    command:bw-verify)           CURSOR_DESCRIPTION="Buildwright bw-verify: quick quality checks (typecheck, lint, test, build)" ;;
    command:bw-analyse)          CURSOR_DESCRIPTION="Buildwright bw-analyse: analyse codebase, write structured docs to .buildwright/codebase/, update tech.md" ;;
    command:bw-plan)             CURSOR_DESCRIPTION="Buildwright bw-plan: research a question, produce a written deliverable — no implementation" ;;
    agent:staff-engineer)        CURSOR_DESCRIPTION="Buildwright Staff Engineer agent persona" ;;
    agent:security-engineer)     CURSOR_DESCRIPTION="Buildwright Security Engineer agent persona" ;;
    *)                           CURSOR_DESCRIPTION="Buildwright ${preset}: ${filename}" ;;
  esac
}

# strip_frontmatter FILE
# Emits FILE's body with a leading YAML frontmatter block (--- ... ---) removed.
# Files without frontmatter are emitted unchanged. Cursor .mdc files carry their
# own frontmatter, so the source's name/description block must not leak into the
# rule body.
strip_frontmatter() {
  awk '
    NR==1 && $0=="---" { in_fm=1; next }
    in_fm && $0=="---" { in_fm=0; next }
    !in_fm             { print }
  ' "$1"
}

# sync_cursor_dir SRC DST_SUBDIR PRESET
# Converts .md files in SRC to .mdc files in .cursor/rules/DST_SUBDIR,
# prepending YAML frontmatter and rewriting @.buildwright/ → @.cursor/rules/.
# The source's own frontmatter (if any) is stripped first.
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
    rm -rf "$dst"
    mkdir -p "$dst"
  fi

  while IFS= read -r src_file; do
    [ -f "$src_file" ] || continue
    local rel_file filename base_filename
    rel_file="${src_file#$src/}"
    filename="${rel_file%.md}"
    base_filename=$(basename "$filename")

    # Skip meta files — they're internal docs, not rules
    case "$base_filename" in
      README|TEMPLATE) continue ;;
    esac

    local dst_file="$dst/$filename.mdc"
    local dst_parent
    dst_parent=$(dirname "$dst_file")
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
          strip_frontmatter "$src_file" | sed 's|@\.buildwright/|@.cursor/rules/|g'
        } > "$tmpfile"
        if ! diff -q "$dst_file" "$tmpfile" > /dev/null 2>&1; then
          echo "OUT OF SYNC: $dst_file"
          SYNC_NEEDED=true
        fi
        rm -f "$tmpfile"
      fi
    else
      mkdir -p "$dst_parent"
      {
        printf '%s\n' "---"
        printf 'description: "%s"\n' "$CURSOR_DESCRIPTION"
        printf '%s\n' "globs: []"
        printf 'alwaysApply: %s\n' "$CURSOR_ALWAYS_APPLY"
        printf '%s\n' "---"
        strip_frontmatter "$src_file" | sed 's|@\.buildwright/|@.cursor/rules/|g'
      } > "$dst_file"
    fi
  done < <(find "$src" -type f -name "*.md" | sort)

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
sync_dir ".buildwright/framework" ".claude/framework" ".buildwright/" ".claude/"
sync_dir ".buildwright/steering"  ".claude/steering"
sync_dir ".buildwright/codebase"  ".claude/codebase"

# ============================================================================
# 2. .buildwright/ → .opencode/ (rewrite .buildwright/ → .opencode/)
# ============================================================================

sync_dir ".buildwright/commands"  ".opencode/commands"  ".buildwright/" ".opencode/"
sync_dir ".buildwright/agents"    ".opencode/agents"    ".buildwright/" ".opencode/"
sync_dir ".buildwright/framework" ".opencode/framework" ".buildwright/" ".opencode/"
sync_dir ".buildwright/steering"  ".opencode/steering"
sync_dir ".buildwright/codebase"  ".opencode/codebase"

# ============================================================================
# 3. .buildwright/ → .cursor/rules/ (convert to .mdc with frontmatter)
# ============================================================================

sync_cursor_dir ".buildwright/framework" "framework" "framework"
sync_cursor_dir ".buildwright/steering"  "steering"  "steering"
sync_cursor_dir ".buildwright/codebase"  "codebase"  "codebase"
sync_cursor_dir ".buildwright/commands"  "commands"  "command"
sync_cursor_dir ".buildwright/agents"    "agents"    "agent"

# ============================================================================
# 4. .buildwright/commands/ → skills/ (Codex CLI skill discovery)
# ============================================================================

if [ "$CHECK_ONLY" = false ]; then
  rm -rf skills
  for file in .buildwright/commands/bw-*.md; do
    [ -f "$file" ] || continue
    name=$(basename "$file" .md)
    mkdir -p "skills/$name"
    cp "$file" "skills/$name/SKILL.md"
    echo "  synced $file → skills/$name/SKILL.md"
  done
fi

# ============================================================================
# 5. Package for ClawHub (dist/)
# ============================================================================

if [ "$CHECK_ONLY" = false ] && [ -f "SKILL.md" ]; then
  mkdir -p dist/buildwright
  cp SKILL.md dist/buildwright/
  echo "  packaged dist/buildwright/SKILL.md for ClawHub"
fi

# ============================================================================
# 6. README.md → cli/README.md (single source of truth for npm package page)
# Only runs in the buildwright repo itself, which has a cli/ directory.
# Generated services do not have cli/ and must not fail here.
# ============================================================================

if [ "$CHECK_ONLY" = false ] && [ -f "README.md" ] && [ -d "cli" ]; then
  cp README.md cli/README.md
  echo "  README.md → cli/README.md"
fi

# ============================================================================
# Result
# ============================================================================

if [ "$CHECK_ONLY" = true ]; then
  if [ "$SYNC_NEEDED" = true ]; then
    echo ""
    echo "Run '.buildwright/scripts/sync-agents.sh' to fix."
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
  if [ -f "SKILL.md" ]; then
    echo "  SKILL.md      → dist/buildwright/SKILL.md"
  fi
  echo "  .buildwright/commands/ → skills/          (Codex CLI skill discovery)"
  if [ -d "cli" ]; then
    echo "  README.md     → cli/README.md             (npm package page)"
  fi

  # Validate all commands are documented in SKILL.md and README.md
  if [ -f ".buildwright/scripts/validate-docs.sh" ]; then
    echo ""
    bash .buildwright/scripts/validate-docs.sh || true
  fi
fi
