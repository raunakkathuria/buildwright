'use strict';

const fs = require('fs');
const path = require('path');

const MARKER = '# --- buildwright generated ---';
const STEERING_ENTRY = '.claude/steering/';
const CODEBASE_ENTRY = '.claude/codebase/';
const BLOCK = `${MARKER}
# Generated from .buildwright/ by the Buildwright sync — do not commit.
.claude/agents/
.claude/framework/
${STEERING_ENTRY}
${CODEBASE_ENTRY}
.claude/skills/bw-*/
.claude/settings.local.json
.opencode/
.cursor/rules/
.agents/skills/bw-*/
`;

function validateGitignore(cwd) {
  const file = path.join(cwd, '.gitignore');
  let stat;
  try {
    stat = fs.lstatSync(file);
  } catch (err) {
    if (err.code !== 'ENOENT') throw err;
  }
  if (stat && (stat.isSymbolicLink() || !stat.isFile())) {
    throw new Error('Refusing to modify .gitignore: expected a regular file, not a symlink or directory');
  }
  return stat;
}

/**
 * Ensure the Buildwright generated-dirs block is present in the project's
 * .gitignore. Existing marker-managed blocks are migrated when a generated
 * entry is added. Unrelated project entries are never modified.
 * Returns true when the file changed.
 */
function appendGitignoreBlock(cwd) {
  const file = path.join(cwd, '.gitignore');
  const stat = validateGitignore(cwd);

  const current = stat ? fs.readFileSync(file, 'utf8') : '';
  const parts = current.split(/(\r\n|\n)/);
  const markerPart = parts.findIndex((part, index) => index % 2 === 0 && part === MARKER);
  if (markerPart >= 0) {
    const hasCodebaseEntry = parts.some(
      (part, index) => index % 2 === 0 && part === CODEBASE_ENTRY,
    );
    if (hasCodebaseEntry) return false;

    const steeringPart = parts.findIndex(
      (part, index) => index > markerPart && index % 2 === 0 && part === STEERING_ENTRY,
    );
    const anchorPart = steeringPart >= 0 ? steeringPart : markerPart;
    const separator = parts[anchorPart + 1] || (current.includes('\r\n') ? '\r\n' : '\n');
    if (parts[anchorPart + 1]) {
      parts.splice(anchorPart + 2, 0, CODEBASE_ENTRY, separator);
    } else {
      parts.splice(anchorPart + 1, 0, separator, CODEBASE_ENTRY);
    }
    fs.writeFileSync(file, parts.join(''));
    return true;
  }
  let prefix = '';
  if (current !== '') {
    prefix = current.endsWith('\n') ? '\n' : '\n\n';
  }
  fs.appendFileSync(file, prefix + BLOCK);
  return true;
}

module.exports = { appendGitignoreBlock, validateGitignore, MARKER };
