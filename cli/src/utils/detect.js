'use strict';

const fs = require('fs');
const path = require('path');

/**
 * Check if current directory is a git repository.
 * Walks up the directory tree looking for a .git directory.
 */
function isGitRepo(cwd) {
  let dir = cwd;
  while (true) {
    if (fs.existsSync(path.join(dir, '.git'))) return true;
    const parent = path.dirname(dir);
    if (parent === dir) return false;
    dir = parent;
  }
}

/**
 * Check if Buildwright is already installed in the given directory.
 */
function isBuildwrightInstalled(cwd) {
  return fs.existsSync(path.join(cwd, '.buildwright'));
}

module.exports = { isGitRepo, isBuildwrightInstalled };
