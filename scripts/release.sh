#!/usr/bin/env bash
set -euo pipefail

BUMP="${1:-patch}"

# Guard: working tree must be clean before we start
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: working tree has uncommitted changes. Commit or stash before releasing."
  exit 1
fi

# Step 1: bump version files (cli/package.json + SKILL.md + make sync)
make bump BUMP="$BUMP"

# Read new version from the bumped package.json
NEW_VERSION=$(node -p "require('./cli/package.json').version")

# Step 2: commit version files
git add cli/package.json cli/package-lock.json SKILL.md
git commit -m "chore: bump version to v$NEW_VERSION"

# Step 3: push commit first
git push

# Step 4: annotated tag (after commit is on remote)
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
git push origin "v$NEW_VERSION"

# Step 5: GitHub release with auto-generated notes
gh release create "v$NEW_VERSION" --title "v$NEW_VERSION" --generate-notes

# Step 6: publish to npm
cd cli && npm publish

echo ""
echo "✓ Released v$NEW_VERSION"
echo "  GitHub: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/v$NEW_VERSION"
echo "  npm:    https://www.npmjs.com/package/buildwright/v/$NEW_VERSION"
