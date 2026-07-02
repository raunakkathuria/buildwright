'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const https = require('https');
const { execSync } = require('child_process');
const { isBuildwrightInstalled } = require('../utils/detect');
const { copyDir, chmodScripts } = require('../utils/copy-files');
const { runSync, runInstallHooks } = require('../utils/run-script');
const { appendGitignoreBlock } = require('../utils/gitignore');

// ANSI colours
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const BOLD = '\x1b[1m';
const RESET = '\x1b[0m';

const GITHUB_REPO = 'raunakkathuria/buildwright';
// `framework` (Buildwright-owned behaviour docs), `commands`, `agents`, and
// `scripts` (support scripts + git hooks) are fully overwritten on update via
// copyDir. `steering` is project-owned and uses the hash-managed preserve
// logic below.
const UPDATE_DIRS = ['commands', 'agents', 'framework', 'scripts', 'steering'];

// Files Buildwright used to ship at the project root (pre-0.0.18 layout).
// Each is removed on update iff its content contains the marker (i.e. it is
// the Buildwright-shipped copy, not something the project customized).
const LEGACY_FILES = {
  'scripts/sync-agents.sh': '.buildwright',
  'scripts/validate-docs.sh': '.buildwright',
  'scripts/validate-skill.sh': 'Agent Skills specification',
  'scripts/install-hooks.sh': 'Buildwright',
  'scripts/bump-version.sh': '.buildwright',
  'scripts/release.sh': '.buildwright',
  'scripts/hooks/pre-commit': 'Buildwright',
  'scripts/hooks/post-merge': 'Buildwright',
  'scripts/hooks/post-checkout': 'Buildwright',
  'Makefile': '.cursor/rules/ from .buildwright/',
};

/**
 * Remove pre-0.0.18 Buildwright files from the project root. Only exact known
 * paths whose content carries the Buildwright marker are deleted; anything
 * customized is left in place. No-op inside the framework repo itself.
 * Returns the removed paths.
 */
function removeLegacyFiles(cwd) {
  if (fs.existsSync(path.join(cwd, 'cli', 'templates'))) return [];
  const removed = [];
  for (const [rel, marker] of Object.entries(LEGACY_FILES)) {
    const file = path.join(cwd, rel);
    if (!fs.existsSync(file)) continue;
    if (fs.readFileSync(file, 'utf8').includes(marker)) {
      fs.rmSync(file);
      removed.push(rel);
    }
  }
  for (const dir of ['scripts/hooks', 'scripts']) {
    const p = path.join(cwd, dir);
    if (fs.existsSync(p) && fs.readdirSync(p).length === 0) fs.rmdirSync(p);
  }
  return removed;
}

// Steering files Buildwright ships and may update in place. Keyed by filename,
// each value is the set of SHA-256 hashes of every version Buildwright has ever
// shipped for that file. An existing steering file is overwritten on update ONLY
// when its hash is in this set (i.e. it is an unmodified, previously-shipped
// copy); a customized file (hash absent) is preserved. Files Buildwright does not
// ship at all are never touched.
//
// RELEASE STEP: whenever a managed steering file changes, append the superseded
// version's SHA-256 here so unmodified installs keep auto-updating.
const MANAGED_STEERING_HASHES = {
  'philosophy.md': new Set([
    '476fe491e139a211d9483942bd60435513813227c589ae0c29ba1e082672757a',
  ]),
};

function sha256(filePath) {
  return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex');
}

/**
 * Copy shipped steering files into dest. New shipped files are added. An existing
 * file is overwritten only when its content matches a known shipped hash (i.e. the
 * user has not customized it); customized or unmanaged files are preserved. Files
 * not shipped by Buildwright are never touched. Steering is a flat dir of .md files.
 * @param {object} [managedHashes] - filename -> Set of known shipped hashes
 * @returns {{updated: string[], preserved: string[]}}
 */
function updateSteering(src, dest, managedHashes = MANAGED_STEERING_HASHES) {
  fs.mkdirSync(dest, { recursive: true });
  const updated = [];
  const preserved = [];
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    if (!entry.isFile()) continue;
    const realSrc = fs.realpathSync(path.join(src, entry.name));
    const destPath = path.join(dest, entry.name);
    if (!fs.existsSync(destPath)) {
      fs.copyFileSync(realSrc, destPath);
      updated.push(entry.name);
      continue;
    }
    const known = managedHashes[entry.name];
    const localHash = sha256(destPath);
    if (known && known.has(localHash)) {
      if (sha256(realSrc) !== localHash) {
        fs.copyFileSync(realSrc, destPath);
        updated.push(entry.name);
      }
    } else {
      preserved.push(entry.name);
    }
  }
  return { updated, preserved };
}

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

async function update() {
  const cwd = process.cwd();

  if (!isBuildwrightInstalled(cwd)) {
    console.log(`${YELLOW}Buildwright is not installed in this directory.${RESET}`);
    console.log(`Run ${BOLD}buildwright init${RESET} first.`);
    process.exit(1);
  }

  console.log(`${BOLD}Updating Buildwright in ${cwd}...${RESET}\n`);
  console.log(`Updating: ${UPDATE_DIRS.map(d => `.buildwright/${d}/`).join(', ')}`);
  console.log(`Preserving: customized and org-injected steering files (only an unmodified philosophy.md is refreshed)\n`);

  let tmpDir;
  try {
    const result = await downloadAndExtract();
    tmpDir = result.tmpDir;
    const extractedRoot = result.extractedRoot;

    const srcBuildwright = path.join(extractedRoot, '.buildwright');
    if (!fs.existsSync(srcBuildwright)) {
      throw new Error('Downloaded archive is missing .buildwright/ directory');
    }

    for (const dir of UPDATE_DIRS) {
      const src = path.join(srcBuildwright, dir);
      const dest = path.join(cwd, '.buildwright', dir);
      if (!fs.existsSync(src)) {
        console.log(`  ${YELLOW}Skipping ${dir}/ (not found in latest release)${RESET}`);
        continue;
      }
      console.log(`  Updating .buildwright/${dir}/`);
      fs.mkdirSync(dest, { recursive: true });
      if (dir === 'steering') {
        const { preserved } = updateSteering(src, dest);
        if (preserved.length > 0) {
          console.log(`    Preserved customized steering files: ${preserved.join(', ')}`);
        }
      } else {
        copyDir(src, dest);
      }
    }
    chmodScripts(path.join(cwd, '.buildwright', 'scripts'));

    // Migrate pre-0.0.18 installs: drop Buildwright-shipped root files
    const removed = removeLegacyFiles(cwd);
    if (removed.length > 0) {
      console.log(`  Removed legacy root files (now under .buildwright/scripts/): ${removed.join(', ')}`);
    }
    appendGitignoreBlock(cwd);

    // Add the canonical AGENTS.md and the CLAUDE.md pointer stub if absent
    // locally. Existing files are left untouched (treated as user-owned).
    for (const file of ['AGENTS.md', 'CLAUDE.md']) {
      const src = path.join(extractedRoot, file);
      const dest = path.join(cwd, file);
      if (fs.existsSync(src) && !fs.existsSync(dest)) {
        console.log(`  Adding ${file}`);
        fs.copyFileSync(src, dest);
      }
    }

    console.log('');

    // Reinstall hooks (older installs' .git/hooks copies call `make sync`)
    if (fs.existsSync(path.join(cwd, '.git'))) {
      runInstallHooks(cwd);
    }

    // Re-run sync
    console.log(`${CYAN}Running Buildwright sync...${RESET}`);
    const syncOk = runSync(cwd);
    if (!syncOk) {
      console.log(`${YELLOW}Warning: sync failed. Run ${BOLD}bash .buildwright/scripts/sync-agents.sh${RESET}${YELLOW} manually.${RESET}`);
    }

    console.log('');
    console.log(`${GREEN}${BOLD}Update complete!${RESET}`);
    console.log('commands, agents, framework, and default steering updated.');
    console.log('Your custom files are unchanged.\n');

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

module.exports = { update, updateSteering, removeLegacyFiles, MANAGED_STEERING_HASHES };
