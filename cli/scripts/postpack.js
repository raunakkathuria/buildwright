#!/usr/bin/env node
/**
 * postpack.js — Run after `npm pack` or `npm publish`.
 *
 * Restores the symlinks in cli/templates/ that were replaced with real
 * files by prepack.js, so the development setup stays in sync with the
 * canonical source files.
 */
'use strict';

const fs = require('fs');
const path = require('path');

const templatesDir = path.join(__dirname, '..', 'templates');
const symlinkMapFile = path.join(__dirname, '..', '.symlink-map.json');

if (!fs.existsSync(symlinkMapFile)) {
  console.log('postpack: .symlink-map.json not found — nothing to restore.');
  process.exit(0);
}

const symlinkMap = JSON.parse(fs.readFileSync(symlinkMapFile, 'utf8'));

for (const [entry, linkTarget] of Object.entries(symlinkMap)) {
  const entryPath = path.join(templatesDir, entry);

  if (fs.existsSync(entryPath)) {
    console.log(`  Removing real copy: templates/${entry}`);
    fs.rmSync(entryPath, { recursive: true, force: true });
  }

  console.log(`  Restoring symlink: templates/${entry} -> ${linkTarget}`);
  fs.symlinkSync(linkTarget, entryPath);
}

// Clean up the map file
fs.unlinkSync(symlinkMapFile);
console.log('postpack: symlinks restored.');
