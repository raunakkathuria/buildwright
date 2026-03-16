#!/usr/bin/env node
/**
 * prepack.js — Run before `npm pack` or `npm publish`.
 *
 * When git core.symlinks=true  → templates/ entries are real symlinks.
 * When git core.symlinks=false → templates/ entries are text files whose
 *   entire content is the symlink target path (e.g. "../../scripts").
 *
 * In both cases npm pack does not follow directory symlinks outside the
 * package root, so this script resolves each entry to a real copy of its
 * target before packing. postpack.js restores the originals afterwards.
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

  let linkTarget = null;

  if (lstat.isSymbolicLink()) {
    // core.symlinks=true: real symlink
    linkTarget = fs.readlinkSync(entryPath);
  } else if (lstat.isFile()) {
    // core.symlinks=false: git stores symlinks as text files containing the target path
    const content = fs.readFileSync(entryPath, 'utf8').trim();
    if (/^\.\.\//.test(content) && !content.includes('\n')) {
      linkTarget = content;
    }
  }

  if (!linkTarget) continue;

  const realTarget = path.resolve(path.dirname(entryPath), linkTarget);
  if (!fs.existsSync(realTarget)) {
    console.warn(`  Warning: target not found for templates/${entry} -> ${linkTarget}`);
    continue;
  }

  console.log(`  Resolving: templates/${entry} -> ${linkTarget}`);
  symlinkMap[entry] = linkTarget;

  fs.rmSync(entryPath, { recursive: true, force: true });
  copyRecursive(realTarget, entryPath);
}

fs.writeFileSync(symlinkMapFile, JSON.stringify(symlinkMap, null, 2));
console.log(`prepack: templates/ resolved. Map saved to .symlink-map.json`);
