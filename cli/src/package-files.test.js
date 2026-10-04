'use strict';

const test = require('node:test');
const assert = require('node:assert');
const path = require('path');
const { execFileSync } = require('child_process');

const cliRoot = path.join(__dirname, '..');

// --ignore-scripts skips prepack/postpack, which rewrite templates/ in place.
function packedFiles() {
  const out = execFileSync('npm', ['pack', '--dry-run', '--json', '--ignore-scripts'], {
    cwd: cliRoot,
    encoding: 'utf8',
  });
  return JSON.parse(out)[0].files.map((f) => f.path);
}

test('the npm package leaves out test files', () => {
  const files = packedFiles();

  assert.ok(files.includes('bin/buildwright.js'), 'package must still ship the CLI');
  assert.deepStrictEqual(files.filter((f) => f.endsWith('.test.js')), []);
});
