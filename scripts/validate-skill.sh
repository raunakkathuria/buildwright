#!/bin/bash
# Validate SKILL.md against the Agent Skills specification (agentskills.io)
#
# Checks:
#   1. YAML frontmatter exists and is valid
#   2. Required fields: name, description
#   3. Recommended fields: license, compatibility, metadata
#   4. File size under 500 lines (best practice)
#
# Usage: scripts/validate-skill.sh [path/to/SKILL.md]

set -e

SKILL_FILE="${1:-SKILL.md}"

if [ ! -f "$SKILL_FILE" ]; then
  echo "ERROR: $SKILL_FILE not found"
  exit 1
fi

ERRORS=0
WARNINGS=0

echo "Validating $SKILL_FILE against Agent Skills spec..."
echo ""

# ============================================================================
# Check 1: YAML frontmatter exists
# ============================================================================

if ! head -1 "$SKILL_FILE" | grep -q "^---$"; then
  echo "ERROR: Missing YAML frontmatter (file must start with ---)"
  ERRORS=$((ERRORS + 1))
else
  echo "  [PASS] YAML frontmatter exists"
fi

# Check frontmatter closing (count lines that are exactly ---)
DELIM_COUNT=$(grep -c "^---$" "$SKILL_FILE" || true)
if [ "$DELIM_COUNT" -lt 2 ]; then
  echo "ERROR: YAML frontmatter not properly closed (missing second ---)"
  ERRORS=$((ERRORS + 1))
else
  echo "  [PASS] YAML frontmatter properly closed"
fi

# ============================================================================
# Check 2: Required fields
# ============================================================================

# Extract frontmatter
FRONTMATTER=$(awk '/^---$/{n++; next} n==1{print} n==2{exit}' "$SKILL_FILE")

if echo "$FRONTMATTER" | grep -q "^name:"; then
  echo "  [PASS] Required field: name"
else
  echo "ERROR: Missing required field: name"
  ERRORS=$((ERRORS + 1))
fi

if echo "$FRONTMATTER" | grep -q "^description:"; then
  echo "  [PASS] Required field: description"
else
  echo "ERROR: Missing required field: description"
  ERRORS=$((ERRORS + 1))
fi

# ============================================================================
# Check 3: Recommended fields
# ============================================================================

if echo "$FRONTMATTER" | grep -q "^license:"; then
  echo "  [PASS] Recommended field: license"
else
  echo "  [WARN] Missing recommended field: license"
  WARNINGS=$((WARNINGS + 1))
fi

if echo "$FRONTMATTER" | grep -q "^compatibility:"; then
  echo "  [PASS] Recommended field: compatibility"
else
  echo "  [WARN] Missing recommended field: compatibility"
  WARNINGS=$((WARNINGS + 1))
fi

if echo "$FRONTMATTER" | grep -q "^metadata:"; then
  echo "  [PASS] Recommended field: metadata"
else
  echo "  [WARN] Missing recommended field: metadata"
  WARNINGS=$((WARNINGS + 1))
fi

# ============================================================================
# Check 4: Metadata sub-fields
# ============================================================================

if echo "$FRONTMATTER" | grep -q "version:"; then
  echo "  [PASS] Metadata: version"
else
  echo "  [WARN] Missing metadata: version"
  WARNINGS=$((WARNINGS + 1))
fi

if echo "$FRONTMATTER" | grep -q "author:"; then
  echo "  [PASS] Metadata: author"
else
  echo "  [WARN] Missing metadata: author"
  WARNINGS=$((WARNINGS + 1))
fi

if echo "$FRONTMATTER" | grep -q "tags:"; then
  echo "  [PASS] Metadata: tags (improves discoverability)"
else
  echo "  [WARN] Missing metadata: tags (recommended for ClawHub/marketplace discoverability)"
  WARNINGS=$((WARNINGS + 1))
fi

# ============================================================================
# Check 5: File size
# ============================================================================

LINE_COUNT=$(wc -l < "$SKILL_FILE")
if [ "$LINE_COUNT" -gt 500 ]; then
  echo "  [WARN] SKILL.md is $LINE_COUNT lines (recommended: under 500)"
  WARNINGS=$((WARNINGS + 1))
else
  echo "  [PASS] File size: $LINE_COUNT lines (under 500)"
fi

# ============================================================================
# Check 6: Markdown body exists after frontmatter
# ============================================================================

BODY_LINES=$(awk '/^---$/{n++; next} n>=2{print}' "$SKILL_FILE" | grep -c "." || true)
if [ "$BODY_LINES" -lt 5 ]; then
  echo "  [WARN] Markdown body is very short ($BODY_LINES non-empty lines)"
  WARNINGS=$((WARNINGS + 1))
else
  echo "  [PASS] Markdown body: $BODY_LINES non-empty lines"
fi

# ============================================================================
# Result
# ============================================================================

echo ""
echo "═══════════════════════════════════════"
if [ "$ERRORS" -gt 0 ]; then
  echo "  FAILED: $ERRORS error(s), $WARNINGS warning(s)"
  echo "═══════════════════════════════════════"
  exit 1
else
  echo "  PASSED: 0 errors, $WARNINGS warning(s)"
  echo "═══════════════════════════════════════"
  exit 0
fi
