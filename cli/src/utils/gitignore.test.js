'use strict';

const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const { appendGitignoreBlock, MARKER } = require('./gitignore');

const CODEBASE_ENTRY = '.claude/codebase/';

function tmpProject() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'bw-gitignore-test-'));
}

function count(content, needle) {
  return content.split(needle).length - 1;
}

test('fresh install ignores generated Claude codebase docs', () => {
  const root = tmpProject();

  assert.strictEqual(appendGitignoreBlock(root), true);

  const content = fs.readFileSync(path.join(root, '.gitignore'), 'utf8');
  assert.match(content, /^\.claude\/codebase\/$/m);
});

test('update migrates an existing marker-managed block', () => {
  const root = tmpProject();
  const file = path.join(root, '.gitignore');
  const existing = `dist/\n\n${MARKER}\n# Generated from .buildwright/ by the Buildwright sync — do not commit.\n.claude/steering/\n.opencode/\ncustom-project-entry/\n`;
  fs.writeFileSync(file, existing);

  assert.strictEqual(appendGitignoreBlock(root), true);

  const content = fs.readFileSync(file, 'utf8');
  // Every missing block entry is added (grouped after the last existing block
  // entry), including the Kiro steering line, while unrelated entries stay.
  assert.match(content, /^\.claude\/codebase\/$/m);
  assert.match(content, /^\.kiro\/steering\/bw-\*\.md$/m);
  assert.match(content, /^custom-project-entry\/$/m);
  // The Kiro line follows an existing block entry, not the trailing custom one.
  assert.match(content, /^\.opencode\/\n[\s\S]*^\.kiro\/steering\/bw-\*\.md$/m);
});

test('gitignore migration is idempotent', () => {
  const root = tmpProject();

  assert.strictEqual(appendGitignoreBlock(root), true);
  assert.strictEqual(appendGitignoreBlock(root), false);

  const content = fs.readFileSync(path.join(root, '.gitignore'), 'utf8');
  assert.strictEqual(count(content, MARKER), 1);
  assert.strictEqual(count(content, CODEBASE_ENTRY), 1);
});

test('update adds the Kiro ignore line to a pre-Kiro (0.0.22) block, once', () => {
  const root = tmpProject();
  const file = path.join(root, '.gitignore');
  // A marker block as shipped in 0.0.22: has .claude/codebase/ but no .kiro line.
  const existing = `${MARKER}\n# Generated from .buildwright/ by the Buildwright sync — do not commit.\n.claude/agents/\n.claude/framework/\n.claude/steering/\n.claude/codebase/\n.claude/skills/bw-*/\n.claude/settings.local.json\n.opencode/\n.cursor/rules/\n.agents/skills/bw-*/\n`;
  fs.writeFileSync(file, existing);

  // First update adds the missing Kiro line and reports a change.
  assert.strictEqual(appendGitignoreBlock(root), true);
  let content = fs.readFileSync(file, 'utf8');
  assert.match(content, /^\.kiro\/steering\/bw-\*\.md$/m);
  assert.strictEqual(count(content, '.kiro/steering/bw-*.md'), 1);
  assert.strictEqual(count(content, MARKER), 1);

  // Second update is a no-op (nothing missing).
  assert.strictEqual(appendGitignoreBlock(root), false);
  content = fs.readFileSync(file, 'utf8');
  assert.strictEqual(count(content, '.kiro/steering/bw-*.md'), 1);
});

test('migration preserves CRLF line endings', () => {
  const root = tmpProject();
  const file = path.join(root, '.gitignore');
  fs.writeFileSync(file, `${MARKER}\r\n.claude/steering/\r\n.opencode/\r\n`);

  appendGitignoreBlock(root);

  const content = fs.readFileSync(file, 'utf8');
  // Missing entries are appended after the last existing block entry, keeping
  // CRLF throughout (no bare LF introduced).
  assert.match(content, /\.opencode\/\r\n\.claude\/agents\/\r\n/);
  assert.match(content, /\.kiro\/steering\/bw-\*\.md\r\n/);
  assert.doesNotMatch(content, /(?<!\r)\n/);
});

test('migration preserves mixed line endings and unrelated bytes', () => {
  const root = tmpProject();
  const file = path.join(root, '.gitignore');
  const existing = `first/\n${MARKER}\r\n.claude/steering/\r\n.opencode/\nlast/\n`;
  fs.writeFileSync(file, existing);

  appendGitignoreBlock(root);

  assert.strictEqual(
    fs.readFileSync(file, 'utf8'),
    `first/\n${MARKER}\r\n.claude/steering/\r\n.opencode/\n.claude/agents/\n.claude/framework/\n.claude/codebase/\n.claude/skills/bw-*/\n.claude/settings.local.json\n.cursor/rules/\n.agents/skills/bw-*/\n.kiro/steering/bw-*.md\nlast/\n`,
  );
});

test('missing entries are added under the marker, not in a later user section', () => {
  const root = tmpProject();
  const file = path.join(root, '.gitignore');
  // The marker block ends at the blank line; the user kept `.cursor/rules/`
  // (a block entry) in their own section further down. The missing Kiro line
  // must land under the marker, immediately after the block's last entry
  // (`.opencode/`), not next to the relocated `.cursor/rules/` below.
  const existing =
    `${MARKER}\n` +
    `# Generated from .buildwright/ by the Buildwright sync — do not commit.\n` +
    `.claude/agents/\n.claude/framework/\n.claude/steering/\n.claude/codebase/\n` +
    `.claude/skills/bw-*/\n.claude/settings.local.json\n.opencode/\n.agents/skills/bw-*/\n` +
    `\n# my own section\n.cursor/rules/\n`;
  fs.writeFileSync(file, existing);

  assert.strictEqual(appendGitignoreBlock(root), true);
  const content = fs.readFileSync(file, 'utf8');

  // The Kiro line sits right after the block's last entry, before the blank line.
  assert.match(content, /\.agents\/skills\/bw-\*\/\n\.kiro\/steering\/bw-\*\.md\n\n# my own section\n/);
  // The user's relocated entry and its heading are untouched and appear once.
  assert.strictEqual(count(content, '.cursor/rules/'), 1);
  assert.match(content, /# my own section\n\.cursor\/rules\/\n$/);
});

test('refuses a symlinked gitignore without mutating its target', () => {
  const root = tmpProject();
  const project = path.join(root, 'project');
  const target = path.join(root, 'outside.gitignore');
  const original = `${MARKER}\n.claude/steering/\n`;
  fs.mkdirSync(project);
  fs.writeFileSync(target, original);
  fs.symlinkSync(target, path.join(project, '.gitignore'));

  assert.throws(() => appendGitignoreBlock(project), /regular file, not a symlink/);
  assert.strictEqual(fs.readFileSync(target, 'utf8'), original);
});

test('init rejects a symlinked gitignore before creating project files', () => {
  const root = tmpProject();
  const project = path.join(root, 'project');
  const target = path.join(root, 'outside.gitignore');
  fs.mkdirSync(project);
  fs.writeFileSync(target, 'outside/\n');
  fs.symlinkSync(target, path.join(project, '.gitignore'));

  const cli = path.resolve(__dirname, '..', '..', 'bin', 'buildwright.js');
  const result = spawnSync(process.execPath, [cli, 'init'], {
    cwd: project,
    encoding: 'utf8',
  });

  assert.notStrictEqual(result.status, 0);
  assert.match(`${result.stdout}${result.stderr}`, /Refusing to modify \.gitignore/);
  assert.strictEqual(fs.existsSync(path.join(project, '.buildwright')), false);
  assert.strictEqual(fs.readFileSync(target, 'utf8'), 'outside/\n');
});

test('curl and npm installers use the same generated ignore block', () => {
  const setup = fs.readFileSync(path.resolve(__dirname, '..', '..', '..', 'setup.sh'), 'utf8');
  const root = tmpProject();
  appendGitignoreBlock(root);
  const npmBlock = fs.readFileSync(path.join(root, '.gitignore'), 'utf8');
  const setupBlock = setup.match(/cat >> \.gitignore <<'EOF'\n([\s\S]*?)\nEOF/)?.[1];

  assert.ok(setupBlock, 'setup.sh must contain the generated .gitignore block');
  assert.strictEqual(`${setupBlock}\n`, npmBlock);
  assert.match(setup, /Refusing to modify a non-regular or symlinked \.gitignore/);
});
