#!/usr/bin/env node
'use strict';

const { Command } = require('commander');
const { init } = require('../src/commands/init');
const { update } = require('../src/commands/update');
const { sync } = require('../src/commands/sync');
const { commands } = require('../src/commands/commands');

const pkg = require('../package.json');

const program = new Command();

program
  .name('buildwright')
  .description('Lightweight engineering workflow for agent-led development')
  .version(pkg.version);

program
  .command('init')
  .description('Set up Buildwright in the current project')
  .action(() => {
    init();
  });

program
  .command('update')
  .description('Update commands, agents, and default steering from GitHub')
  .action(async () => {
    await update();
  });

program
  .command('sync')
  .description('Re-sync .buildwright/ to the generated tool configs (.claude/, .opencode/, .cursor/rules/, .agents/skills/)')
  .action(() => {
    sync();
  });

program
  .command('commands')
  .description('List available agent slash commands (/bw-*)')
  .action(() => {
    commands();
  });

program.parse(process.argv);
