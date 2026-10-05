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
.kiro/steering/bw-*.md
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
 * .gitignore. When the marker block already exists, every BLOCK entry that is
 * missing is appended to it (so upgrades pick up newly generated paths such as
 * the Kiro steering docs). Unrelated project entries are never modified.
 * Returns true when the file changed.
 */
function appendGitignoreBlock(cwd) {
  const file = path.join(cwd, '.gitignore');
  const stat = validateGitignore(cwd);

  const current = stat ? fs.readFileSync(file, 'utf8') : '';
  const parts = current.split(/(\r\n|\n)/);
  const markerPart = parts.findIndex((part, index) => index % 2 === 0 && part === MARKER);
  if (markerPart >= 0) {
    // The ignore-pattern lines in BLOCK (skip the marker and the comment line).
    const blockEntries = BLOCK.split('\n')
      .filter((line) => line !== '' && line !== MARKER && !line.startsWith('#'));

    // Entries already present anywhere in the file (even outside the block)
    // are treated as covered, so we never duplicate a line a user kept.
    const existing = new Set(
      parts.filter((part, index) => index % 2 === 0 && part !== ''),
    );
    const missing = blockEntries.filter((entry) => !existing.has(entry));
    if (missing.length === 0) return false;

    // Insert the missing entries immediately after the last existing block
    // entry, so they stay grouped under the marker. Scan only within the marker
    // block: a blank line ends the block (so entries a user relocated into a
    // later section do not drag the anchor out), comment lines inside the block
    // are skipped, and any other non-block line also ends the scan.
    let anchorPart = markerPart;
    for (let index = markerPart + 2; index < parts.length; index += 2) {
      const line = parts[index];
      if (line === '') break;
      if (blockEntries.includes(line)) {
        anchorPart = index;
        continue;
      }
      if (line.startsWith('#')) continue;
      break;
    }
    const separator = parts[anchorPart + 1] || (current.includes('\r\n') ? '\r\n' : '\n');
    const insertion = [];
    for (const entry of missing) {
      insertion.push(entry, separator);
    }
    if (parts[anchorPart + 1]) {
      parts.splice(anchorPart + 2, 0, ...insertion);
    } else {
      parts.splice(anchorPart + 1, 0, separator, ...insertion.slice(0, -1));
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
