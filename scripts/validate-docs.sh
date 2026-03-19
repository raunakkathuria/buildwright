#!/usr/bin/env bash
# validate-docs.sh — checks that every bw-* command is documented in SKILL.md and README.md
# Run automatically by sync-agents.sh after each sync.
# Exit code 1 if any commands are missing from documentation.

set -euo pipefail

COMMANDS_DIR=".buildwright/commands"
SKILL_MD="SKILL.md"
README_MD="README.md"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

if [ ! -d "$COMMANDS_DIR" ]; then
  echo "  validate-docs: $COMMANDS_DIR not found, skipping"
  exit 0
fi

missing=0

for file in "$COMMANDS_DIR"/bw-*.md; do
  [ -f "$file" ] || continue

  # Skip bw-help.md — it IS the help output, doesn't need its own docs section
  basename=$(basename "$file")
  [ "$basename" = "bw-help.md" ] && continue

  # Extract name from YAML frontmatter
  name=$(awk '/^---/{f=!f;next} f && /^name:/{print $2;exit}' "$file" 2>/dev/null | tr -d '\r')

  if [ -z "$name" ]; then
    echo -e "  ${YELLOW}validate-docs: $basename has no 'name' in frontmatter — skipping${RESET}"
    continue
  fi

  cmd="/$name"
  file_missing=0

  # Check SKILL.md
  if [ -f "$SKILL_MD" ] && ! grep -qi "### $cmd" "$SKILL_MD" 2>/dev/null; then
    echo -e "  ${RED}${BOLD}validate-docs: $cmd missing from SKILL.md${RESET}"
    file_missing=1
    missing=$((missing + 1))
  fi

  # Check README.md
  if [ -f "$README_MD" ] && ! grep -q "$cmd" "$README_MD" 2>/dev/null; then
    echo -e "  ${RED}${BOLD}validate-docs: $cmd missing from README.md${RESET}"
    file_missing=1
    missing=$((missing + 1))
  fi

  if [ "$file_missing" -eq 0 ]; then
    echo -e "  ${GREEN}validate-docs: $cmd ✓${RESET}"
  fi
done

if [ "$missing" -gt 0 ]; then
  echo ""
  echo -e "  ${RED}${BOLD}validate-docs: $missing documentation gap(s) found.${RESET}"
  echo -e "  Update README.md and SKILL.md, then re-run 'make sync'."
  exit 1
fi
