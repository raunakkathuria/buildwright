'use strict';

const test = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { updateSteering } = require('./update');

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

  const { added, preserved } = updateSteering(src, dest);

  assert.deepStrictEqual(added, ['philosophy.md']);
  assert.deepStrictEqual(preserved, []);
  assert.strictEqual(fs.readFileSync(path.join(dest, 'philosophy.md'), 'utf8'), 'NEW philosophy');
});

test('never modifies an existing steering file (project-owned)', () => {
  const { src, dest } = tmpProject();
  const existing = 'my philosophy, possibly customized';
  fs.writeFileSync(path.join(dest, 'philosophy.md'), existing);
  fs.writeFileSync(path.join(src, 'philosophy.md'), 'NEW philosophy');

  const { added, preserved } = updateSteering(src, dest);

  assert.deepStrictEqual(added, []);
  assert.deepStrictEqual(preserved, ['philosophy.md']);
  assert.strictEqual(fs.readFileSync(path.join(dest, 'philosophy.md'), 'utf8'), existing);
});

test('never touches an org steering file that Buildwright does not ship', () => {
  const { src, dest } = tmpProject();
  fs.writeFileSync(path.join(src, 'philosophy.md'), 'NEW philosophy');
  const orgDoc = 'org quality gates';
  fs.writeFileSync(path.join(dest, 'quality-gates.md'), orgDoc);

  updateSteering(src, dest);

  assert.strictEqual(fs.readFileSync(path.join(dest, 'quality-gates.md'), 'utf8'), orgDoc);
});
