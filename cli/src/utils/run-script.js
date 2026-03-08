'use strict';

const { execSync, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

/**
 * Run a shell command synchronously in the given directory.
 * Prints output as it runs. Returns true on success.
 */
function run(command, cwd) {
  try {
    execSync(command, { cwd, stdio: 'inherit' });
    return true;
  } catch {
    return false;
  }
}

/**
 * Run make sync or fall back to running sync-agents.sh directly.
 * Returns true on success.
 */
function runSync(cwd) {
  const makefile = path.join(cwd, 'Makefile');
  if (fs.existsSync(makefile)) {
    if (run('make sync', cwd)) return true;
  }
  const syncScript = path.join(cwd, 'scripts', 'sync-agents.sh');
  if (fs.existsSync(syncScript)) {
    chmodX(syncScript);
    return run(`bash "${syncScript}"`, cwd);
  }
  return false;
}

/**
 * Run make install-hooks or fall back to install-hooks.sh directly.
 * Returns true on success.
 */
function runInstallHooks(cwd) {
  const makefile = path.join(cwd, 'Makefile');
  if (fs.existsSync(makefile)) {
    if (run('make install-hooks', cwd)) return true;
  }
  const hooksScript = path.join(cwd, 'scripts', 'install-hooks.sh');
  if (fs.existsSync(hooksScript)) {
    chmodX(hooksScript);
    return run(`bash "${hooksScript}"`, cwd);
  }
  return false;
}

/**
 * Make a file executable.
 */
function chmodX(filePath) {
  try {
    fs.chmodSync(filePath, 0o755);
  } catch {
    // ignore
  }
}

module.exports = { run, runSync, runInstallHooks, chmodX };
