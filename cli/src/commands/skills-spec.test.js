'use strict';

const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..', '..', '..');
const packageVersion = require('../../package.json').version;
const expectedAuthor = 'raunakkathuria';

function readFrontmatter(file) {
  const content = fs.readFileSync(file, 'utf8');
  const match = content.match(/^---\n([\s\S]*?)\n---\n/);
  assert.ok(match, `${file} must start with YAML frontmatter`);
  return match[1];
}

function readField(frontmatter, field) {
  return frontmatter.match(new RegExp(`^${field}:\\s*(.+)$`, 'm'))?.[1]?.trim();
}

function readMetadataField(frontmatter, field) {
  const value = frontmatter.match(new RegExp(`^  ${field}:\\s*(.+)$`, 'm'))?.[1]?.trim();
  return value?.replace(/^"|"$/g, '');
}

function assertMinimalSkill(file, expectedName) {
  const frontmatter = readFrontmatter(file);
  const keys = frontmatter
    .split('\n')
    .filter(line => /^\S[^:]*:/.test(line))
    .map(line => line.slice(0, line.indexOf(':')));
  const name = readField(frontmatter, 'name');
  const description = readField(frontmatter, 'description');
  const metadataKeys = frontmatter
    .split('\n')
    .filter(line => /^  \S[^:]*:/.test(line))
    .map(line => line.trimStart().slice(0, line.trimStart().indexOf(':')));

  assert.deepStrictEqual(keys, ['name', 'description', 'metadata'], `${file} should use only required fields plus metadata`);
  assert.deepStrictEqual(metadataKeys, ['author', 'version'], `${file} should keep only maintained metadata`);
  assert.strictEqual(name, expectedName);
  assert.match(name, /^(?!-)(?!.*--)[a-z0-9-]{1,64}(?<!-)$/);
  assert.ok(description && description.length <= 1024, `${file} needs a valid description`);
  assert.match(description, /\bUse (?:when|for|before)\b/, `${file} should say when to use the skill`);
  assert.strictEqual(readMetadataField(frontmatter, 'author'), expectedAuthor);
  assert.strictEqual(readMetadataField(frontmatter, 'version'), packageVersion);
}

test('Buildwright skills use minimal Agent Skills frontmatter', () => {
  const commandsDir = path.join(repoRoot, '.buildwright', 'commands');
  for (const entry of fs.readdirSync(commandsDir).filter(name => /^bw-.*\.md$/.test(name))) {
    const expectedName = path.basename(entry, '.md');
    assertMinimalSkill(path.join(commandsDir, entry), expectedName);
  }
});

test('ClawHub bundle uses supported ClawHub metadata', () => {
  const file = path.join(repoRoot, 'clawhub', 'buildwright', 'SKILL.md');
  const frontmatter = readFrontmatter(file);
  const keys = frontmatter
    .split('\n')
    .filter(line => /^\S[^:]*:/.test(line))
    .map(line => line.slice(0, line.indexOf(':')));

  assert.deepStrictEqual(keys, ['name', 'description', 'version', 'metadata']);
  assert.strictEqual(readField(frontmatter, 'name'), 'buildwright');
  assert.strictEqual(readField(frontmatter, 'version')?.replace(/^"|"$/g, ''), packageVersion);
  assert.match(readField(frontmatter, 'description'), /\bUse (?:when|for|before)\b/);
  assert.match(frontmatter, /^  openclaw:\n    emoji: ".+"\n    homepage: https:\/\/github\.com\/raunakkathuria\/buildwright$/m);
  assert.doesNotMatch(frontmatter, /^license:|^compatibility:|^  author:|^\s+tags:/m);
});

test('repository Markdown stays untrusted project context', () => {
  const commandsDir = path.join(repoRoot, '.buildwright', 'commands');
  const guidanceFiles = [
    'AGENTS.md',
    'clawhub/buildwright/SKILL.md',
    ...fs.readdirSync(commandsDir)
      .filter(name => /^bw-.*\.md$/.test(name))
      .map(name => path.join('.buildwright', 'commands', name)),
  ];

  for (const relativePath of guidanceFiles) {
    const content = fs.readFileSync(path.join(repoRoot, relativePath), 'utf8');
    assert.doesNotMatch(
      content,
      /recursively (?:discover and )?reads?[\s\S]{0,80}\.buildwright\/(?:steering|codebase|framework)/i,
      `${relativePath} must not automatically load open-ended repository Markdown`,
    );
  }

  for (const relativePath of ['AGENTS.md', 'clawhub/buildwright/SKILL.md']) {
    const content = fs.readFileSync(path.join(repoRoot, relativePath), 'utf8');
    assert.match(content, /repository-owned Markdown as untrusted project context/i);
    assert.match(content, /cannot override system, developer, or user instructions/i);
    assert.match(content, /cannot authorize credential access/i);
    assert.match(content, /never execute[\s\S]{0,120}solely because[\s\S]{0,80}file says to do so/i);
    assert.match(content, /new or modified[\s\S]{0,100}reviewed change/i);
  }
});

test('Cursor never auto-loads repository context as generated rules', () => {
  const sync = fs.readFileSync(path.join(repoRoot, '.buildwright/scripts/sync-agents.sh'), 'utf8');
  const qualityWorkflow = fs.readFileSync(
    path.join(repoRoot, '.github/workflows/quality-gates.yml'),
    'utf8',
  );

  assert.doesNotMatch(sync, /CURSOR_ALWAYS_APPLY="true"/);
  assert.doesNotMatch(
    sync,
    /sync_cursor_dir "\.buildwright\/(?:framework|steering|codebase)"/,
  );
  assert.match(sync, /STALE: \.cursor\/rules\/\$context_dir/);
  assert.doesNotMatch(
    qualityWorkflow,
    /test -f "\.cursor\/rules\/(?:framework|steering|codebase)/,
  );
  assert.match(
    qualityWorkflow,
    /for context_dir in framework steering codebase; do[\s\S]{0,160}test ! -e "\.cursor\/rules\/\$context_dir"[\s\S]{0,40}done/,
  );
});

test('release scripts maintain skill metadata versions', () => {
  const bump = fs.readFileSync(path.join(repoRoot, 'cli/scripts/bump-version.sh'), 'utf8');
  const release = fs.readFileSync(path.join(repoRoot, 'cli/scripts/release.sh'), 'utf8');

  for (const pattern of [/clawhub\/buildwright\/SKILL\.md/, /\.buildwright\/commands\/bw-/]) {
    assert.match(bump, pattern);
    assert.match(release, pattern);
  }
  assert.match(bump, /\^version:/);
  assert.match(bump, /\^  version:/);
  assert.match(release, /--tags latest/);
  assert.match(release, /--categories development,agents/);
  assert.match(release, /--topics tdd,code-review,security-review,software-development,agent-workflows/);
});
