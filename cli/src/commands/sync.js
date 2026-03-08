'use strict';

const { isBuildwrightInstalled } = require('../utils/detect');
const { runSync } = require('../utils/run-script');

const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const BOLD = '\x1b[1m';
const RESET = '\x1b[0m';

function sync() {
  const cwd = process.cwd();

  if (!isBuildwrightInstalled(cwd)) {
    console.log(`${YELLOW}Buildwright is not installed in this directory.${RESET}`);
    console.log(`Run ${BOLD}buildwright init${RESET} first.`);
    process.exit(1);
  }

  console.log(`${CYAN}Syncing .buildwright/ to tool configs...${RESET}`);
  const ok = runSync(cwd);

  if (ok) {
    console.log(`${GREEN}${BOLD}Sync complete!${RESET}`);
    console.log('.claude/, .opencode/, .cursor/rules/, and AGENTS.md are up to date.');
  } else {
    console.log(`${YELLOW}Sync failed. Make sure make is installed or run scripts/sync-agents.sh directly.${RESET}`);
    process.exit(1);
  }
}

module.exports = { sync };
