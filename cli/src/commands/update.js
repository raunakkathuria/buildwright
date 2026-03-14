'use strict';

const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');
const { isBuildwrightInstalled } = require('../utils/detect');
const { copyDir } = require('../utils/copy-files');
const { runSync } = require('../utils/run-script');

// ANSI colours
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const BOLD = '\x1b[1m';
const RESET = '\x1b[0m';

const GITHUB_REPO = 'raunakkathuria/buildwright';
const UPDATE_DIRS = ['commands', 'agents', 'claws'];

/**
 * Download a URL following redirects. Returns a Buffer.
 */
function download(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'buildwright-cli' } }, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        return download(res.headers.location).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`HTTP ${res.statusCode} for ${url}`));
      }
      const chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', reject);
    }).on('error', reject);
  });
}

/**
 * Download and extract the GitHub tarball to a temp directory.
 * Returns the path to the extracted root.
 */
async function downloadAndExtract() {
  const tmpDir = fs.mkdtempSync(path.join(require('os').tmpdir(), 'buildwright-update-'));
  const tarPath = path.join(tmpDir, 'buildwright.tar.gz');

  console.log(`${CYAN}Downloading latest Buildwright from GitHub...${RESET}`);
  const url = `https://api.github.com/repos/${GITHUB_REPO}/tarball/main`;
  const data = await download(url);
  fs.writeFileSync(tarPath, data);

  console.log(`${CYAN}Extracting...${RESET}`);
  execSync(`tar xzf "${tarPath}" -C "${tmpDir}"`, { stdio: 'pipe' });

  // The tarball extracts to a directory like raunakkathuria-buildwright-<sha>/
  const entries = fs.readdirSync(tmpDir).filter(e => e !== 'buildwright.tar.gz');
  if (entries.length === 0) throw new Error('Tarball extraction produced no files');

  const extractedRoot = path.join(tmpDir, entries[0]);
  return { tmpDir, extractedRoot };
}

/**
 * Copy files from src to dest, but only files that exist in src.
 * Files in dest that have no counterpart in src are left untouched.
 */
function copyUpstreamOnly(src, dest) {
  for (const entry of fs.readdirSync(src)) {
    const srcEntry = path.join(src, entry);
    const destEntry = path.join(dest, entry);
    const stat = fs.statSync(srcEntry);
    if (stat.isDirectory()) {
      fs.mkdirSync(destEntry, { recursive: true });
      copyUpstreamOnly(srcEntry, destEntry);
    } else {
      if (!fs.existsSync(destEntry)) {
        fs.copyFileSync(srcEntry, destEntry);  // only new files
      }
    }
  }
}

async function update() {
  const cwd = process.cwd();

  if (!isBuildwrightInstalled(cwd)) {
    console.log(`${YELLOW}Buildwright is not installed in this directory.${RESET}`);
    console.log(`Run ${BOLD}buildwright init${RESET} first.`);
    process.exit(1);
  }

  console.log(`${BOLD}Updating Buildwright in ${cwd}...${RESET}\n`);
  console.log(`Updating: ${UPDATE_DIRS.map(d => `.buildwright/${d}/`).join(', ')}`);
  console.log(`Preserving: .buildwright/steering/ (your customizations)\n`);

  let tmpDir;
  try {
    const result = await downloadAndExtract();
    tmpDir = result.tmpDir;
    const extractedRoot = result.extractedRoot;

    const srcBuildwright = path.join(extractedRoot, '.buildwright');
    if (!fs.existsSync(srcBuildwright)) {
      throw new Error('Downloaded archive is missing .buildwright/ directory');
    }

    // Update only the specified directories — overwrite upstream files only,
    // never delete files the user added that don't exist in the upstream source.
    for (const dir of UPDATE_DIRS) {
      const src = path.join(srcBuildwright, dir);
      const dest = path.join(cwd, '.buildwright', dir);
      if (!fs.existsSync(src)) {
        console.log(`  ${YELLOW}Skipping ${dir}/ (not found in latest release)${RESET}`);
        continue;
      }
      console.log(`  Updating .buildwright/${dir}/ (adding new files only)`);
      fs.mkdirSync(dest, { recursive: true });
      // Copy only files that exist in upstream — preserves user-added files
      copyUpstreamOnly(src, dest);
    }

    // Also add CLAUDE.md if it doesn't already exist locally
    const srcClaude = path.join(extractedRoot, 'CLAUDE.md');
    const destClaude = path.join(cwd, 'CLAUDE.md');
    if (fs.existsSync(srcClaude) && !fs.existsSync(destClaude)) {
      console.log(`  Adding CLAUDE.md`);
      fs.copyFileSync(srcClaude, destClaude);
    }

    console.log('');

    // Re-run sync
    console.log(`${CYAN}Running make sync...${RESET}`);
    const syncOk = runSync(cwd);
    if (!syncOk) {
      console.log(`${YELLOW}Warning: make sync failed. Run ${BOLD}make sync${RESET}${YELLOW} manually.${RESET}`);
    }

    console.log('');
    console.log(`${GREEN}${BOLD}Update complete!${RESET}`);
    console.log('commands, agents, and claws: new files added. Existing files unchanged.');
    console.log('Your custom files and steering docs are unchanged.\n');

  } catch (err) {
    console.error(`\nUpdate failed: ${err.message}`);
    console.error(`You can update manually by downloading from: https://github.com/${GITHUB_REPO}`);
    process.exit(1);
  } finally {
    if (tmpDir) {
      try { fs.rmSync(tmpDir, { recursive: true, force: true }); } catch { /* ignore */ }
    }
  }
}

module.exports = { update };
