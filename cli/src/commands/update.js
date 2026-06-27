'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
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
// `framework` (Buildwright-owned behaviour docs) and `commands`/`agents` are
// fully overwritten on update via copyDir. `steering` is project-owned and uses
// the hash-managed preserve logic below.
const UPDATE_DIRS = ['commands', 'agents', 'framework', 'steering'];
const SUPPORT_FILES = [
  'scripts/sync-agents.sh',
  'scripts/validate-docs.sh',
  'scripts/validate-skill.sh',
  'scripts/install-hooks.sh',
  'scripts/hooks/pre-commit',
  'scripts/hooks/post-merge',
  'scripts/hooks/post-checkout',
];

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

    for (const file of SUPPORT_FILES) {
      const src = path.join(extractedRoot, file);
      const dest = path.join(cwd, file);
      if (!fs.existsSync(src)) continue;
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.copyFileSync(src, dest);
    }
    console.log(`  Updated Buildwright support scripts`);

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

    // Re-run sync
    console.log(`${CYAN}Running make sync...${RESET}`);
    const syncOk = runSync(cwd);
    if (!syncOk) {
      console.log(`${YELLOW}Warning: make sync failed. Run ${BOLD}make sync${RESET}${YELLOW} manually.${RESET}`);
    }

    console.log('');
    console.log(`${GREEN}${BOLD}Update complete!${RESET}`);
    console.log('commands, agents, and default steering updated.');
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

module.exports = { update, updateSteering, MANAGED_STEERING_HASHES };
