'use strict';

const fs = require('fs');
const path = require('path');

const CYAN = '\x1b[36m';
const BOLD = '\x1b[1m';
const RESET = '\x1b[0m';
const DIM = '\x1b[2m';

const HARDCODED = [
  { name: 'bw-analyse',     description: 'Analyse codebase: writes stack, architecture, conventions, concerns to .buildwright/codebase/' },
  { name: 'bw-claw',        description: 'Multi-agent: architect decomposes → claws execute per domain' },
  { name: 'bw-new-feature', description: 'Full pipeline: research → spec → approve → build → ship' },
  { name: 'bw-plan',        description: 'Research a question, produce a written deliverable — no implementation, no commits' },
  { name: 'bw-quick',       description: 'Fast path for bug fixes, small tasks, config changes' },
  { name: 'bw-ship',        description: 'Quality gates + release: verify → security → review → push → PR' },
  { name: 'bw-verify',      description: 'Quick checks: typecheck, lint, test, build' },
];

function parseFrontmatter(content) {
  const parts = content.split('---');
  if (parts.length < 3) return null;
  const front = parts[1];
  const name = front.match(/^name:\s*(.+)$/m)?.[1]?.trim();
  const description = front.match(/^description:\s*(.+)$/m)?.[1]?.trim();
  return name && description ? { name, description } : null;
}

function loadFromDir(dir) {
  const files = fs.readdirSync(dir).filter(f => f.startsWith('bw-') && f.endsWith('.md') && f !== 'bw-help.md');
  const entries = [];
  for (const file of files) {
    const content = fs.readFileSync(path.join(dir, file), 'utf8');
    const parsed = parseFrontmatter(content);
    if (parsed) entries.push(parsed);
  }
  return entries.sort((a, b) => a.name.localeCompare(b.name));
}

function formatList(entries) {
  const maxLen = Math.max(...entries.map(e => e.name.length));
  return entries.map(({ name, description }) => {
    const padded = `/${name}`.padEnd(maxLen + 2);
    return `  ${BOLD}${padded}${RESET}  ${DIM}${description}${RESET}`;
  }).join('\n');
}

function commands() {
  const cwd = process.cwd();
  const commandsDir = path.join(cwd, '.buildwright', 'commands');

  let entries;
  let source;

  if (fs.existsSync(commandsDir)) {
    entries = loadFromDir(commandsDir);
    source = 'project';
  } else {
    entries = HARDCODED;
    source = 'default';
  }

  console.log('');
  console.log(`${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════════╗${RESET}`);
  console.log(`${CYAN}${BOLD}║              AGENT SLASH COMMANDS                             ║${RESET}`);
  console.log(`${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════════╝${RESET}`);
  console.log('');
  console.log('Use these inside Claude Code, Cursor, or OpenCode:');
  console.log('');
  console.log(formatList(entries));
  console.log('');
  if (source === 'default') {
    console.log(`${DIM}(Showing default commands. Run inside a Buildwright project to see project-specific commands.)${RESET}`);
    console.log('');
  }
  console.log(`Run ${BOLD}buildwright help${RESET} for CLI setup commands.`);
  console.log('');
}

module.exports = { commands };
