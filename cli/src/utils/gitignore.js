'use strict';

const fs = require('fs');
const path = require('path');

const MARKER = '# --- buildwright generated ---';
const BLOCK = `${MARKER}
# Generated from .buildwright/ by the Buildwright sync — do not commit.
.claude/agents/
.claude/framework/
.claude/steering/
.claude/skills/bw-*/
.claude/settings.local.json
.opencode/
.cursor/rules/
.agents/skills/bw-*/
.kiro/steering/bw-*.md
.kiro/hooks/bw-*.kiro.hook
`;

/**
 * Append the Buildwright generated-dirs block to the project's .gitignore.
 * Creates the file if absent; idempotent (skips when the marker is present).
 * Never modifies existing entries. Returns true if the block was added.
 */
function appendGitignoreBlock(cwd) {
  const file = path.join(cwd, '.gitignore');
  const current = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  if (current.includes(MARKER)) return false;
  let prefix = '';
  if (current !== '') {
    prefix = current.endsWith('\n') ? '\n' : '\n\n';
  }
  fs.appendFileSync(file, prefix + BLOCK);
  return true;
}

module.exports = { appendGitignoreBlock, MARKER };
