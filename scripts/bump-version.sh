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

# 3. Update SKILL.md frontmatter
sed -i.bak "s/^  version: \".*\"/  version: \"$NEW_VERSION\"/" SKILL.md
rm -f SKILL.md.bak

# 4. Sync dist/
make sync

echo ""
echo "✓ Bumped to v$NEW_VERSION"
echo ""
echo "Next steps:"
echo "  git add cli/package.json SKILL.md"
echo "  git commit -m \"chore: bump version to $NEW_VERSION\""
echo "  git tag v$NEW_VERSION"
echo "  cd cli && npm publish"
echo "  make dist   # then upload dist/buildwright/ to clawhub.ai"
