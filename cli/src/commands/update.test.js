'use strict';

const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');

const { updateSteering, REMOVED_PATHS, MANAGED_STEERING_HASHES } = require('./update');

const sha256 = (s) => crypto.createHash('sha256').update(s).digest('hex');

function tmpProject() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'bw-update-test-'));
  const src = path.join(root, 'src');
  const dest = path.join(root, 'dest');
  fs.mkdirSync(src, { recursive: true });
  fs.mkdirSync(dest, { recursive: true });
  return { root, src, dest };
}

test('copies a shipped steering file that is absent locally', () => {
  const { src, dest } = tmpProject();
  fs.writeFileSync(path.join(src, 'philosophy.md'), 'NEW philosophy');

  const { updated, preserved } = updateSteering(src, dest, {});

  assert.deepStrictEqual(updated, ['philosophy.md']);
  assert.deepStrictEqual(preserved, []);
  assert.strictEqual(fs.readFileSync(path.join(dest, 'philosophy.md'), 'utf8'), 'NEW philosophy');
});

test('overwrites an unmodified shipped file (hash match) with the latest', () => {
  const { src, dest } = tmpProject();
  const oldContent = 'OLD philosophy';
  fs.writeFileSync(path.join(dest, 'philosophy.md'), oldContent);
  fs.writeFileSync(path.join(src, 'philosophy.md'), 'NEW philosophy');

  const managed = { 'philosophy.md': new Set([sha256(oldContent)]) };
  const { updated, preserved } = updateSteering(src, dest, managed);

  assert.deepStrictEqual(updated, ['philosophy.md']);
  assert.deepStrictEqual(preserved, []);
  assert.strictEqual(fs.readFileSync(path.join(dest, 'philosophy.md'), 'utf8'), 'NEW philosophy');
});

test('preserves a customized steering file (hash not in the managed set)', () => {
  const { src, dest } = tmpProject();
  const customContent = 'CUSTOM org philosophy';
  fs.writeFileSync(path.join(dest, 'philosophy.md'), customContent);
  fs.writeFileSync(path.join(src, 'philosophy.md'), 'NEW philosophy');

  // managed set only knows some other (shipped) hash, not the custom content
  const managed = { 'philosophy.md': new Set([sha256('some shipped version')]) };
  const { updated, preserved } = updateSteering(src, dest, managed);

  assert.deepStrictEqual(updated, []);
  assert.deepStrictEqual(preserved, ['philosophy.md']);
  assert.strictEqual(fs.readFileSync(path.join(dest, 'philosophy.md'), 'utf8'), customContent);
});

test('never touches an org steering file that Buildwright does not ship', () => {
  const { src, dest } = tmpProject();
  // Buildwright ships only philosophy.md
  fs.writeFileSync(path.join(src, 'philosophy.md'), 'NEW philosophy');
  // org injected its own doc at a colliding-style path
  const orgDoc = 'org quality gates';
  fs.writeFileSync(path.join(dest, 'quality-gates.md'), orgDoc);

  updateSteering(src, dest, MANAGED_STEERING_HASHES);

  assert.strictEqual(fs.existsSync(path.join(dest, 'quality-gates.md')), true);
  assert.strictEqual(fs.readFileSync(path.join(dest, 'quality-gates.md'), 'utf8'), orgDoc);
});

test('REMOVED_PATHS no longer deletes org-injected steering docs', () => {
  assert.ok(!REMOVED_PATHS.includes('.buildwright/steering/quality-gates.md'));
  assert.ok(!REMOVED_PATHS.includes('.buildwright/steering/naming-conventions.md'));
  assert.ok(!REMOVED_PATHS.includes('.buildwright/steering/engineering-philosophy.md'));
});

test('REMOVED_PATHS still cleans up non-steering legacy paths', () => {
  assert.ok(REMOVED_PATHS.includes('.buildwright/commands/bw-quick.md'));
  assert.ok(REMOVED_PATHS.includes('.buildwright/agents/architect.md'));
});
