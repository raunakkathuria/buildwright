#!/usr/bin/env node
'use strict';

const { Command } = require('commander');
const { init } = require('../src/commands/init');
const { update } = require('../src/commands/update');
const { sync } = require('../src/commands/sync');

const pkg = require('../package.json');

const program = new Command();

program
  .name('buildwright')
  .description('Agent-first autonomous development workflow')
  .version(pkg.version);

program
  .command('init')
  .description('Set up Buildwright in the current project')
  .action(() => {
    init();
  });

program
  .command('update')
  .description('Update commands, agents, and claws from GitHub (preserves steering docs)')
  .action(async () => {
    await update();
  });

program
  .command('sync')
  .description('Re-sync .buildwright/ to .claude/, .opencode/, and .cursor/rules/')
  .action(() => {
    sync();
  });

program.parse(process.argv);
