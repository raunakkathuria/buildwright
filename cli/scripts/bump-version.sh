#!/usr/bin/env bash
set -euo pipefail

# npm versions that are reserved/broken and must never be published
BLOCKED_VERSIONS=("1.0.0" "1.0.1" "1.0.2")

BUMP="${1:-patch}"   # patch | minor | major

# 1. Bump cli/package.json (no git tag yet)
cd cli
npm version "$BUMP" --no-git-tag-version
NEW_VERSION=$(node -p "require('./package.json').version")

# 2. Check if new version is blocked — if so, keep patching until clear
while printf '%s\n' "${BLOCKED_VERSIONS[@]}" | grep -qx "$NEW_VERSION"; do
  echo "⚠️  Version $NEW_VERSION is reserved on npm — skipping to next patch..."
  npm version patch --no-git-tag-version
  NEW_VERSION=$(node -p "require('./package.json').version")
done
cd ..

# 3. Keep the ClawHub bundle version in lockstep with the package.
CLAWHUB_SKILL="clawhub/buildwright/SKILL.md"
if ! grep -q '^version: ".*"$' "$CLAWHUB_SKILL"; then
  echo "✗ $CLAWHUB_SKILL must contain a top-level version." >&2
  exit 1
fi
sed -i.bak "s/^version: \".*\"/version: \"$NEW_VERSION\"/" "$CLAWHUB_SKILL"
rm -f "$CLAWHUB_SKILL.bak"

# 4. Keep generated Agent Skills metadata in lockstep with the package.
SKILL_FILES=()
for cmd in .buildwright/commands/bw-*.md; do
  [ -f "$cmd" ] && SKILL_FILES+=("$cmd")
done

for skill in "${SKILL_FILES[@]}"; do
  if ! grep -q '^  author: raunakkathuria$' "$skill" || ! grep -q '^  version: ".*"$' "$skill"; then
    echo "✗ $skill must contain maintained author and version metadata." >&2
    exit 1
  fi
  sed -i.bak "s/^  version: \".*\"/  version: \"$NEW_VERSION\"/" "$skill"
  rm -f "$skill.bak"
done

# 5. Propagate the canonical command metadata to generated skills.
make sync

echo ""
echo "✓ Bumped to v$NEW_VERSION"
echo ""
echo "Files updated: cli/package.json  cli/package-lock.json  clawhub/buildwright/SKILL.md  .buildwright/commands/bw-*.md"
echo "Run 'make release' to commit, tag, push, create GitHub release, and npm publish."
