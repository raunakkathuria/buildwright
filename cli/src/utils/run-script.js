'use strict';

const { execSync } = require('child_process');
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
 * Run a Buildwright support script from .buildwright/scripts/.
 * Returns true on success, false if the script is missing or fails.
 */
function runBuildwrightScript(name, cwd) {
  const script = path.join(cwd, '.buildwright', 'scripts', name);
  if (!fs.existsSync(script)) return false;
  chmodX(script);
  return run(`bash "${script}"`, cwd);
}

/**
 * Run the Buildwright sync. Returns true on success.
 */
function runSync(cwd) {
  return runBuildwrightScript('sync-agents.sh', cwd);
}

/**
 * Install the Buildwright git hooks. Returns true on success.
 */
function runInstallHooks(cwd) {
  return runBuildwrightScript('install-hooks.sh', cwd);
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
