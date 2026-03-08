'use strict';

const fs = require('fs');
const path = require('path');
const { isGitRepo, isBuildwrightInstalled } = require('../utils/detect');
const { copyDir, chmodScripts } = require('../utils/copy-files');
const { runSync, runInstallHooks } = require('../utils/run-script');

// ANSI colours
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const BOLD = '\x1b[1m';
const RESET = '\x1b[0m';

function init() {
  const cwd = process.cwd();

  // 1. Check git repo
  if (!isGitRepo(cwd)) {
    console.log(`${YELLOW}Warning: No git repository detected in this directory.${RESET}`);
    console.log(`Buildwright works best inside a git repo. Run ${BOLD}git init${RESET} first, then try again.\n`);
    process.exit(1);
  }

  // 2. Check for existing installation
  if (isBuildwrightInstalled(cwd)) {
    console.log(`${YELLOW}Buildwright is already installed in this directory.${RESET}`);
    console.log(`To update commands/agents/claws to the latest version, run: ${BOLD}buildwright update${RESET}`);
    process.exit(1);
  }

  console.log(`${BOLD}Setting up Buildwright in ${cwd}...${RESET}\n`);

  // 3. Copy templates → cwd
  const templatesDir = path.join(__dirname, '..', '..', 'templates');
  if (!fs.existsSync(templatesDir)) {
    console.error('Error: templates directory not found in npm package. Reinstall buildwright.');
    process.exit(1);
  }

  const templateEntries = fs.readdirSync(templatesDir);
  for (const entry of templateEntries) {
    const src = path.join(templatesDir, entry);
    const dest = path.join(cwd, entry);
    const stat = fs.statSync(fs.realpathSync(src));

    if (stat.isDirectory()) {
      console.log(`  Copying ${entry}/`);
      copyDir(src, dest);
    } else {
      console.log(`  Copying ${entry}`);
      fs.copyFileSync(fs.realpathSync(src), dest);
    }
  }

  // 4. chmod +x scripts
  chmodScripts(path.join(cwd, 'scripts'));
  console.log('');

  // 5. Run make sync
  console.log(`${CYAN}Running make sync...${RESET}`);
  const syncOk = runSync(cwd);
  if (!syncOk) {
    console.log(`${YELLOW}Warning: make sync failed. Run ${BOLD}make sync${RESET}${YELLOW} manually after setup.${RESET}`);
  }
  console.log('');

  // 6. Run make install-hooks
  console.log(`${CYAN}Installing git hooks...${RESET}`);
  const hooksOk = runInstallHooks(cwd);
  if (!hooksOk) {
    console.log(`${YELLOW}Warning: hook installation failed. Run ${BOLD}make install-hooks${RESET}${YELLOW} manually.${RESET}`);
  }
  console.log('');

  // 7. Success message
  console.log(`${GREEN}${BOLD}Buildwright is ready!${RESET}\n`);
  console.log('Next steps:');
  console.log(`  1. Edit ${BOLD}.buildwright/steering/product.md${RESET} — add your product context`);
  console.log(`  2. Edit ${BOLD}.buildwright/steering/tech.md${RESET}  — add your tech stack`);
  console.log(`  3. Open your AI editor and run ${BOLD}/bw-new-feature "your feature"${RESET}\n`);
  console.log(`For help: ${BOLD}buildwright --help${RESET}`);
}

module.exports = { init };
