# buildwright

Agent-first autonomous development workflow. Ship code you don't read.

## Install

```bash
npm install -g buildwright
```

Requires Node.js 18+.

## Quick Start

```bash
# Navigate to your project
cd my-project
git init  # if not already a git repo

# Set up Buildwright
buildwright init

# Customize for your project
nano .buildwright/steering/product.md   # add product context
nano .buildwright/steering/tech.md      # add tech stack + commands

# Start building
claude
> /bw-new-feature "Add user authentication"
```

## Commands

| Command | Description |
|---------|-------------|
| `buildwright init` | Set up Buildwright in the current project |
| `buildwright update` | Update commands/agents/claws from GitHub (preserves your steering docs) |
| `buildwright sync` | Re-sync `.buildwright/` to `.claude/`, `.opencode/`, `.cursor/rules/` |

## What `init` Does

1. Copies all Buildwright templates to your project:
   - `.buildwright/` — canonical config (agents, claws, commands, steering)
   - `scripts/` — sync and hook scripts
   - `Makefile`, `CLAUDE.md`, `BUILDWRIGHT.md`
2. Makes scripts executable
3. Runs `make sync` to generate `.claude/`, `.opencode/`, `.cursor/rules/`
4. Installs git hooks for auto-sync on `.buildwright/` changes

## What `update` Does

Downloads the latest release from GitHub and updates:
- `.buildwright/commands/` — slash command definitions
- `.buildwright/agents/` — agent personas
- `.buildwright/claws/` — domain specialist prompts
- `CLAUDE.md` — agent instructions

**Preserves** your customizations in `.buildwright/steering/` (product.md, tech.md, etc.).

## Slash Commands (inside AI editors)

| Command | Purpose |
|---------|---------|
| `/bw-new-feature` | Full pipeline: research → spec → approve → build → ship |
| `/bw-quick` | Fast path for bug fixes, small tasks |
| `/bw-claw` | Cross-domain features (DB + API + UI) |
| `/bw-ship` | Quality gates + push + PR |
| `/bw-verify` | Quick typecheck/lint/test/build |
| `/bw-analyse` | Analyse brownfield codebase |
| `/bw-help` | Show all commands |

## Offline Support

All templates are bundled in the npm package — `buildwright init` works without internet access after installation. Use `buildwright update` to pull the latest templates from GitHub.

## More Information

See the [full documentation](https://github.com/raunakkathuria/buildwright) on GitHub.

## License

MIT
