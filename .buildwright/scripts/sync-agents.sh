#!/bin/bash
# Sync agent configurations across Claude Code, OpenCode, Cursor, and Codex
#
# Source of truth: .buildwright/ (tool-agnostic canonical config)
# Generates:
#   .claude/skills/bw-*/     ← from .buildwright/commands/ (SKILL.md per command)
#   .claude/agents/          ← from .buildwright/agents/
#   .claude/steering/        ← from .buildwright/steering/
#   .opencode/commands/      ← from .buildwright/commands/ (paths rewritten to .opencode/)
#   .opencode/agents/        ← from .buildwright/agents/
#   .opencode/steering/      ← from .buildwright/steering/
#   .cursor/rules/steering/  ← .mdc files with alwaysApply: true
#   .cursor/rules/commands/  ← .mdc files with alwaysApply: false
#   .cursor/rules/agents/    ← .mdc files with alwaysApply: false
#   .agents/skills/          ← per-command SKILL.md for Codex CLI discovery
#   .kiro/steering/bw-framework-*.md  ← from .buildwright/framework/ (inclusion: always)
#   .kiro/steering/bw-steering-*.md   ← from .buildwright/steering/  (inclusion: always)
#   .kiro/steering/bw-codebase-*.md   ← from .buildwright/codebase/  (inclusion: always)
#   .kiro/steering/bw-command-*.md    ← from .buildwright/commands/  (inclusion: manual)
#   .kiro/steering/bw-agent-*.md      ← from .buildwright/agents/    (inclusion: manual)
#   .kiro/hooks/bw-*.kiro.hook        ← from .buildwright/hooks/ (optional)
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

# set_cursor_frontmatter PRESET FILENAME SRC_FILE
# Sets CURSOR_ALWAYS_APPLY (by preset) and CURSOR_DESCRIPTION globals. The
# description is derived from the source file: its frontmatter `description:`
# when present, else its first markdown heading, else a preset fallback.
set_cursor_frontmatter() {
  local preset="$1"
  local filename="$2"
  local src_file="$3"

  case "$preset" in
    steering|codebase|framework) CURSOR_ALWAYS_APPLY="true" ;;
    *)                           CURSOR_ALWAYS_APPLY="false" ;;
  esac

  CURSOR_DESCRIPTION="$(awk '
    NR==1 && $0 !~ /^---/ { exit }
    /^---/ { f++; next }
    f==1 && sub(/^description:[ \t]*/, "") { print; exit }
    f>=2 { exit }
  ' "$src_file")"
  if [ -z "$CURSOR_DESCRIPTION" ]; then
    CURSOR_DESCRIPTION="$(sed -n 's/^# *//p' "$src_file" | head -1)"
  fi
  if [ -z "$CURSOR_DESCRIPTION" ]; then
    CURSOR_DESCRIPTION="Buildwright ${preset}: ${filename}"
  fi
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
    set_cursor_frontmatter "$preset" "$filename" "$src_file"

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

# Claude Code skills (the unified commands+skills format): one
# .claude/skills/<name>/SKILL.md per command, slash-invocable as /<name>.
# Only the bw-* subdirs are Buildwright's — a project's own skills are never
# touched. Legacy .claude/commands/bw-*.md copies are removed.
if [ "$CHECK_ONLY" = false ]; then
  for file in .buildwright/commands/bw-*.md; do
    [ -f "$file" ] || continue
    name=$(basename "$file" .md)
    rm -rf ".claude/skills/$name"
    mkdir -p ".claude/skills/$name"
    cp "$file" ".claude/skills/$name/SKILL.md"
    sed_inplace "s|@@.buildwright/|.claude/|g" ".claude/skills/$name/SKILL.md"
    echo "  synced $file → .claude/skills/$name/SKILL.md"
    rm -f ".claude/commands/$name.md"
  done
  rmdir .claude/commands 2>/dev/null || true
fi
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
# 4. .buildwright/commands/ → .agents/skills/ (Codex CLI project skill
# discovery). Only the bw-* subdirs are Buildwright's — a project's own
# skills in .agents/skills/ are never touched.
# ============================================================================

if [ "$CHECK_ONLY" = false ]; then
  for file in .buildwright/commands/bw-*.md; do
    [ -f "$file" ] || continue
    name=$(basename "$file" .md)
    rm -rf ".agents/skills/$name"
    mkdir -p ".agents/skills/$name"
    cp "$file" ".agents/skills/$name/SKILL.md"
    echo "  synced $file → .agents/skills/$name/SKILL.md"
  done
fi

# ============================================================================
# 5. .buildwright/ → .kiro/ (Kiro steering docs + agent hooks)
#    Generated output is namespaced bw-* and gitignored; existing committed
#    .kiro/steering/*.md project docs are never touched. Every helper below is
#    strictly additive and reuses the existing globals (CHECK_ONLY, SYNC_NEEDED)
#    and helpers (sed_inplace, strip_frontmatter); no existing function is
#    modified. Later tasks append the sync_kiro_* generators to this section.
# ============================================================================

# kiro_frontmatter INCLUSION DESCRIPTION
# Emits a Kiro steering front-matter block to stdout, intended to be written as
# the first bytes of a generated doc (byte offset 0, no preceding whitespace):
# an opening `---`, the `inclusion` field, the `description` field, and a
# closing `---`, each on its own line.
kiro_frontmatter() {
  local inclusion="$1"
  local description="$2"
  printf '%s\n' "---"
  printf 'inclusion: %s\n' "$inclusion"
  printf 'description: "%s"\n' "$description"
  printf '%s\n' "---"
}

# purge_bw_namespace GLOB
# Deletes only generated files matching a bw-* GLOB inside .kiro/steering/ or
# .kiro/hooks/. No-op in CHECK_ONLY mode (never mutates the filesystem during a
# --check run). The per-file `bw-*` basename guard keeps the purge scoped to the
# BW namespace: any path whose name does not start with `bw-` is left untouched.
# set -e safe: a glob that matches nothing stays literal and is skipped by the
# existence check, and `rm -f ... || true` prevents any abort.
purge_bw_namespace() {
  local glob="$1"

  if [ "$CHECK_ONLY" = true ]; then
    return 0
  fi

  local f
  for f in $glob; do
    [ -e "$f" ] || continue
    case "$(basename "$f")" in
      bw-*) rm -f "$f" || true ;;
    esac
  done
  return 0
}

# kiro_ref_rewrite FILE
# Rewrites read-marker references in a generated steering doc from the canonical
# `@@.buildwright/<subdir>/<name>.md` form to the Kiro file-reference form
# `#[[file:.kiro/steering/<prefix><name>.md]]`, using the fixed subdir→prefix
# map below. All five mapped categories flatten into `.kiro/steering/` with a
# `bw-<category>-` prefix (commands/agents are inclusion:manual steering docs).
# Bare `.buildwright/` references (those NOT preceded by `@@`) and every other
# byte of the file are left untouched. Uses only sed_inplace (Requirement 10.3);
# `.` is escaped in the match so it matches a literal dot, and `[[`/`]]` are
# literal in the replacement.
kiro_ref_rewrite() {
  local file="$1"
  local mapping subdir prefix
  for mapping in \
    "framework/:bw-framework-" \
    "steering/:bw-steering-" \
    "codebase/:bw-codebase-" \
    "agents/:bw-agent-" \
    "commands/:bw-command-"; do
    subdir="${mapping%%:*}"
    prefix="${mapping#*:}"
    sed_inplace "s|@@\\.buildwright/${subdir}\\([A-Za-z0-9_-]*\\)\\.md|#[[file:.kiro/steering/${prefix}\\1.md]]|g" "$file"
  done
}

# sync_kiro_steering SRC_DIR NAME_PREFIX INCLUSION
# Generates namespaced Kiro steering docs under .kiro/steering/ from every
# `*.md` in SRC_DIR. Each output is `<NAME_PREFIX><base>.md` carrying an
# `inclusion: <INCLUSION>` front-matter block (byte offset 0) followed by the
# source body with its own front-matter stripped, and with `@@.buildwright/`
# read-markers rewritten to Kiro file references. README/TEMPLATE meta files
# (case-insensitive) are skipped. Honours the existing globals CHECK_ONLY and
# SYNC_NEEDED and reuses kiro_frontmatter, purge_bw_namespace, kiro_ref_rewrite,
# strip_frontmatter, and sed_inplace — no existing function is modified.
#
# Description precedence (Requirements 1.6/1.7/1.8): the source front-matter
# `description:` value, else the source's first markdown heading, else the
# source base name — matching set_cursor_frontmatter's awk/sed derivation.
#
# Collision handling (Requirement 2.6): if two source files in this category
# would flatten to the same `<NAME_PREFIX><base>.md` output (e.g. a nested
# subdir sharing a base name), generation halts with a non-zero return and an
# error naming the conflicting sources, before any on-disk change is made, so
# previously generated docs are left unchanged.
sync_kiro_steering() {
  local src="$1"
  local prefix="$2"
  local inclusion="$3"

  if [ ! -d "$src" ]; then
    return 0
  fi

  # Collision pre-scan (Requirement 2.6): detect two sources mapping to the same
  # output name BEFORE mutating the filesystem, so prior output stays intact on
  # a conflict. Excluded meta files do not participate in the scan.
  local scan_tmp scan_base
  scan_tmp=$(mktemp)
  while IFS= read -r src_file; do
    [ -f "$src_file" ] || continue
    scan_base=$(basename "$src_file" .md)
    case "$scan_base" in
      [Rr][Ee][Aa][Dd][Mm][Ee]|[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee]) continue ;;
    esac
    printf '%s\t%s\n' "${prefix}${scan_base}.md" "$src_file" >> "$scan_tmp"
  done < <(find "$src" -type f -name "*.md" | sort)

  local collisions
  collisions=$(awk -F'\t' '
    { count[$1]++; srcs[$1] = srcs[$1] " " $2 }
    END { for (name in count) if (count[name] > 1) print name ":" srcs[name] }
  ' "$scan_tmp")
  rm -f "$scan_tmp"
  if [ -n "$collisions" ]; then
    echo "ERROR: sync_kiro_steering: output name collision under $src (leaving prior .kiro/steering/${prefix}* unchanged):" >&2
    printf '%s\n' "$collisions" >&2
    return 1
  fi

  if [ "$CHECK_ONLY" = false ]; then
    # Scoped purge: only THIS prefix, never project docs (Requirements 1.4, 3.4).
    purge_bw_namespace ".kiro/steering/${prefix}*.md"
    mkdir -p ".kiro/steering"
  fi

  local src_file base dst_file desc
  while IFS= read -r src_file; do
    [ -f "$src_file" ] || continue
    base=$(basename "$src_file" .md)

    # Skip meta files — they're internal docs, not steering (Requirement 1.5).
    case "$base" in
      [Rr][Ee][Aa][Dd][Mm][Ee]|[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee]) continue ;;
    esac

    dst_file=".kiro/steering/${prefix}${base}.md"

    # Description: front-matter `description:`, else first heading, else base.
    desc="$(awk '
      NR==1 && $0 !~ /^---/ { exit }
      /^---/ { f++; next }
      f==1 && sub(/^description:[ \t]*/, "") { print; exit }
      f>=2 { exit }
    ' "$src_file")"
    if [ -z "$desc" ]; then
      desc="$(sed -n 's/^# *//p' "$src_file" | head -1)"
    fi
    if [ -z "$desc" ]; then
      desc="$base"
    fi

    if [ "$CHECK_ONLY" = true ]; then
      local tmpfile
      tmpfile=$(mktemp)
      {
        kiro_frontmatter "$inclusion" "$desc"
        strip_frontmatter "$src_file"
      } > "$tmpfile"
      kiro_ref_rewrite "$tmpfile"
      if [ ! -f "$dst_file" ]; then
        echo "MISSING: $dst_file"
        SYNC_NEEDED=true
      elif ! diff -q "$dst_file" "$tmpfile" > /dev/null 2>&1; then
        echo "OUT OF SYNC: $dst_file"
        SYNC_NEEDED=true
      fi
      rm -f "$tmpfile"
    else
      {
        kiro_frontmatter "$inclusion" "$desc"
        strip_frontmatter "$src_file"
      } > "$dst_file"
      kiro_ref_rewrite "$dst_file"
    fi
  done < <(find "$src" -type f -name "*.md" | sort)

  if [ "$CHECK_ONLY" = false ]; then
    echo "  synced $src → .kiro/steering/ (${prefix}*)"
  fi
}

# sync_kiro_command_dir SRC_DIR NAME_PREFIX
# Thin wrapper over sync_kiro_steering for the command/agent categories, which
# map to inclusion:manual steering docs (opt-in context invoked with `#<name>`
# in chat, e.g. `#bw-command-<name>` / `#bw-agent-<name>`). It fixes the
# inclusion mode to `manual` and otherwise reuses sync_kiro_steering unchanged.
sync_kiro_command_dir() {
  sync_kiro_steering "$1" "$2" "manual"
}

# sync_kiro_hooks
# Generates Kiro agent-hook manifests under .kiro/hooks/ from the optional
# .buildwright/hooks/ source. Each `*.json` manifest is copied verbatim to
# `.kiro/hooks/bw-<base>.kiro.hook` (base = json filename without extension), so
# the expected output is the source json byte-for-byte. In write mode a scoped
# purge removes stale `.kiro/hooks/bw-*.kiro.hook` first (Requirements 1.4, 3.4).
# The step is a no-op when `.buildwright/hooks/` is absent — the common case, as
# the repo ships no hooks dir today (Requirement 1.4). All writes and the purge
# stay strictly within the `bw-*` hook glob so non-bw hooks are never touched
# (Requirements 3.1, 3.5). Honours CHECK_ONLY: in --check mode it mutates
# nothing, printing `MISSING:`/`OUT OF SYNC:` and setting SYNC_NEEDED=true on
# drift, mirroring sync_kiro_steering / sync_cursor_dir. Reuses only the existing
# toolset (purge_bw_namespace, mktemp, diff, cp) — no new dependency, no existing
# function modified.
sync_kiro_hooks() {
  if [ "$CHECK_ONLY" = false ]; then
    # Scoped purge: only generated bw-* hooks, never a project's own hooks.
    purge_bw_namespace ".kiro/hooks/bw-*.kiro.hook"
  fi

  # Optional source: no manifests dir means nothing to generate (Requirement 1.4).
  if [ ! -d ".buildwright/hooks" ]; then
    return 0
  fi

  if [ "$CHECK_ONLY" = false ]; then
    mkdir -p ".kiro/hooks"
  fi

  local manifest base dst_file
  while IFS= read -r manifest; do
    [ -f "$manifest" ] || continue
    base=$(basename "$manifest" .json)
    dst_file=".kiro/hooks/bw-${base}.kiro.hook"

    if [ "$CHECK_ONLY" = true ]; then
      # Plain copy: expected content is the source manifest byte-for-byte. Build
      # it in a temp file and diff, mirroring the CHECK_ONLY pattern elsewhere.
      local tmpfile
      tmpfile=$(mktemp)
      cat "$manifest" > "$tmpfile"
      if [ ! -f "$dst_file" ]; then
        echo "MISSING: $dst_file"
        SYNC_NEEDED=true
      elif ! diff -q "$dst_file" "$tmpfile" > /dev/null 2>&1; then
        echo "OUT OF SYNC: $dst_file"
        SYNC_NEEDED=true
      fi
      rm -f "$tmpfile"
    else
      cp "$manifest" "$dst_file"
    fi
  done < <(find ".buildwright/hooks" -type f -name "*.json" | sort)

  if [ "$CHECK_ONLY" = false ]; then
    echo "  synced .buildwright/hooks → .kiro/hooks/ (bw-*.kiro.hook)"
  fi
}

# Top-level Kiro target invocation. Runs after the existing targets (sections
# 1-4) so their output is fully written before Kiro runs; a Kiro-target error
# (e.g. the collision halt in sync_kiro_steering) aborts via `set -e` with a
# non-zero exit while leaving existing target output byte-identical (P5,
# Requirement 7.5). The calls are identical in write and --check mode — each
# function honours CHECK_ONLY internally (Requirements 1.1, 2.1, 2.2, 7.2).
sync_kiro_steering ".buildwright/framework" "bw-framework-" "always"
sync_kiro_steering ".buildwright/steering"  "bw-steering-"  "always"
sync_kiro_steering ".buildwright/codebase"  "bw-codebase-"  "always"
sync_kiro_command_dir ".buildwright/commands" "bw-command-"
sync_kiro_command_dir ".buildwright/agents"   "bw-agent-"
sync_kiro_hooks

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
  echo "  .buildwright/commands/ → .agents/skills/  (Codex CLI skill discovery)"
  echo "  .buildwright/ → .kiro/steering/  (bw-* steering docs, gitignored)"
  echo "  .buildwright/hooks/ → .kiro/hooks/  (bw-*.kiro.hook, optional)"

  # Validate all commands are documented in README.md
  if [ -f ".buildwright/scripts/validate-docs.sh" ]; then
    echo ""
    bash .buildwright/scripts/validate-docs.sh || true
  fi
fi
