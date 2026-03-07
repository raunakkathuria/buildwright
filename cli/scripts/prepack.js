#!/usr/bin/env node
/**
 * prepack.js — Run before `npm pack` or `npm publish`.
 *
 * npm pack does not follow symlinks pointing outside the package root.
 * This script resolves each symlink in cli/templates/ to a real copy of its
 * target, so `npm pack` bundles actual content. Run postpack.js after
 * packing to restore the symlinks for development.
 */
'use strict';

const fs = require('fs');
const path = require('path');

const templatesDir = path.join(__dirname, '..', 'templates');
const symlinkMapFile = path.join(__dirname, '..', '.symlink-map.json');

const symlinkMap = {};

function copyRecursive(src, dest) {
  const stat = fs.statSync(src);
  if (stat.isDirectory()) {
    fs.mkdirSync(dest, { recursive: true });
    for (const entry of fs.readdirSync(src)) {
      copyRecursive(path.join(src, entry), path.join(dest, entry));
    }
  } else {
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(src, dest);
  }
}

const entries = fs.readdirSync(templatesDir);
for (const entry of entries) {
  const entryPath = path.join(templatesDir, entry);
  const lstat = fs.lstatSync(entryPath);

  if (lstat.isSymbolicLink()) {
    const linkTarget = fs.readlinkSync(entryPath);
    const realTarget = path.resolve(path.dirname(entryPath), linkTarget);

    console.log(`  Resolving symlink: templates/${entry} -> ${linkTarget}`);

    // Save the link target so postpack.js can restore it
    symlinkMap[entry] = linkTarget;

    // Remove the symlink and copy real content
    fs.unlinkSync(entryPath);
    copyRecursive(realTarget, entryPath);
  }
}

// Write the symlink map so postpack.js can restore
fs.writeFileSync(symlinkMapFile, JSON.stringify(symlinkMap, null, 2));
console.log(`prepack: templates/ resolved to real files. Map saved to .symlink-map.json`);
