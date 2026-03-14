'use strict';

const fs = require('fs');
const path = require('path');

/**
 * Recursively copy src directory to dest directory.
 * Resolves symlinks before copying so npm pack works correctly.
 * @param {string} src - Source directory path
 * @param {string} dest - Destination directory path
 * @param {object} [opts]
 * @param {string[]} [opts.skip] - Relative paths (from src) to skip
 * @param {boolean} [opts.skipExisting] - Skip files that already exist at dest
 */
function copyDir(src, dest, opts = {}) {
  const skip = opts.skip || [];
  const skipExisting = opts.skipExisting || false;
  const entries = fs.readdirSync(src, { withFileTypes: true });
  fs.mkdirSync(dest, { recursive: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    const relativePath = path.relative(src, srcPath);

    if (skip.some(s => relativePath === s || relativePath.startsWith(s + path.sep))) {
      continue;
    }

    // Resolve symlinks
    const realSrcPath = fs.realpathSync(srcPath);
    const stat = fs.statSync(realSrcPath);

    if (stat.isDirectory()) {
      copyDir(realSrcPath, destPath, opts);
    } else {
      if (skipExisting && fs.existsSync(destPath)) {
        // leave existing file untouched
      } else {
        fs.copyFileSync(realSrcPath, destPath);
      }
    }
  }
}

/**
 * Make all .sh files and hook scripts executable under a directory.
 */
function chmodScripts(dir) {
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      chmodScripts(fullPath);
    } else if (entry.name.endsWith('.sh') || !entry.name.includes('.')) {
      // executable if .sh or no extension (hook scripts)
      try {
        fs.chmodSync(fullPath, 0o755);
      } catch {
        // ignore on platforms that don't support chmod
      }
    }
  }
}

module.exports = { copyDir, chmodScripts };
