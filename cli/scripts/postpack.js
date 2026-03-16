#!/usr/bin/env node
/**
 * postpack.js — Run after `npm pack` or `npm publish`.
 *
 * Restores the templates/ entries that prepack.js replaced with real copies.
 * Uses `git checkout` to restore the originals, which correctly handles both:
 *   - core.symlinks=true  → restores as real symlinks
 *   - core.symlinks=false → restores as text stub files
 */
'use strict';

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const cliDir = path.join(__dirname, '..');
const symlinkMapFile = path.join(cliDir, '.symlink-map.json');

if (!fs.existsSync(symlinkMapFile)) {
  console.log('postpack: .symlink-map.json not found — nothing to restore.');
  process.exit(0);
}

try {
  execSync('git checkout -- templates/', { cwd: cliDir, stdio: 'inherit' });
  console.log('postpack: templates/ restored from git.');
} catch (err) {
  console.warn('postpack: git checkout failed — templates/ may need manual restore.');
}

fs.unlinkSync(symlinkMapFile);
