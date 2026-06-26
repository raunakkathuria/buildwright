# Buildwright

Buildwright is a lightweight engineering discipline layer for agent-led
software work: understand, test, implement, document, verify, review, ship.

It is not a multi-agent framework. It keeps a small command surface and stores
only useful project context.

## Commands

| Command | Purpose |
|---------|---------|
| `/bw-plan` | Think/research only; no code changes |
| `/bw-work` | Implement bug fixes, refactors, and features |
| `/bw-verify` | Run typecheck, lint, test, and build gates |
| `/bw-ship` | Security review, code review, push, and PR |
| `/bw-analyse` | Analyse a brownfield codebase and write context docs |

## Workflow

Use `/bw-work` for implementation:

```text
Understand -> Research -> Plan if needed -> Red -> Green -> Refactor -> Docs -> Verify -> Security -> Review -> Commit/Ship
```

Small tasks use lightweight research. Larger features produce
`docs/specs/[feature]/research.md` and `docs/specs/[feature]/spec.md`.
Cross-domain work uses a normal implementation plan; there is no separate
multi-agent architecture.

TDD is explicit:

- Red: write a failing test for the bug or expected behavior.
- Green: make the smallest passing implementation.
- Refactor: improve structure while tests stay green.

Documentation is part of done. Every user-facing change must update affected
README, docs, command text, API docs, examples, or changelog. If no docs apply,
the agent must say why.

## Steering

Buildwright installs one default steering file:

```text
.buildwright/steering/philosophy.md
```

That file contains KISS, YAGNI, DRY, boring technology, fail-fast, TDD,
documentation discipline, and financial-code rules.

Project-specific steering is created only when there is real content:

```text
.buildwright/steering/tech.md       # created after stack/command discovery
.buildwright/steering/product.md    # created for greenfield or explicit product context
```

`/bw-analyse` writes deeper brownfield context to:

```text
.buildwright/codebase/STACK.md
.buildwright/codebase/ARCHITECTURE.md
.buildwright/codebase/CONVENTIONS.md
.buildwright/codebase/CONCERNS.md
```

## Install

### CLI

```bash
npm install -g buildwright
cd your-project
buildwright init
```

Then open your AI editor and run:

```text
/bw-work "your task"
```

### Update

```bash
npm install -g buildwright@latest
cd your-project
buildwright update
```

`buildwright update` refreshes Buildwright commands, agents, default steering,
and Buildwright-owned support scripts. It also removes paths from the old
pre-`/bw-work` model so generated tool configs do not contain both old and new
workflows.

Steering is only touched if Buildwright ships the file. The default
`philosophy.md` is refreshed in place only when it is unmodified (a known shipped
version); a customized `philosophy.md` is preserved. Any steering file Buildwright
does not ship — your `tech.md`, `product.md`, or org-injected docs such as
`quality-gates.md` — is never deleted or overwritten.

### From Source

```bash
git clone https://github.com/raunakkathuria/buildwright.git
cd buildwright
make sync
```

### Global install

Per-project `buildwright init` is the recommended setup — it commits the
workflow config to your repo so it is versioned and shared with your team. If
you would rather have the workflow available in **every** project without
running `init` each time, install it globally from a Buildwright checkout.

```bash
make global      # install for all supported tools at once
```

Or install for a single tool:

| Command | Tool | Installs to |
|---------|------|-------------|
| `make claude` | Claude Code | `~/.claude/commands/`, `~/.claude/agents/` |
| `make codex` | Codex CLI | `~/.agents/skills/buildwright/` (symlink) |
| `make opencode` | OpenCode | `~/.config/opencode/skills/buildwright/` |
| `make openclaw` | OpenClaw | `~/.openclaw/skills/buildwright/` |

Global install makes the **workflow** (the `/bw-*` commands and agents)
discoverable everywhere. Project-specific context — steering docs, tech/product
details, and `/bw-analyse` codebase docs — still comes from each project's
`.buildwright/` directory. In a project without `.buildwright/`, commands fall
back to stack auto-detection, and the `/bw-work` and `/bw-ship` review steps read
the engineer personas from `~/.claude/agents/` (installed by `make claude`). Run
`buildwright init` there when you want full project context (custom steering,
codebase docs).

Note: `make claude` is what installs the `security-engineer` / `staff-engineer`
persona files into `~/.claude/agents/`, so Claude Code's review steps find them
everywhere. The other tools install commands/skills only — under
Codex/OpenCode/OpenClaw the review personas come from a project's
`.buildwright/agents/`, so run `buildwright init` for full reviews there.

Re-run the same command after `git pull` to update. To uninstall:

```bash
rm ~/.claude/commands/bw-*.md ~/.claude/agents/{staff,security}-engineer.md
rm ~/.agents/skills/buildwright                     # codex symlink
rm -rf ~/.config/opencode/skills/buildwright ~/.openclaw/skills/buildwright
```

## Project Layout

```text
.buildwright/
  agents/
    staff-engineer.md
    security-engineer.md
  commands/
    bw-analyse.md
    bw-plan.md
    bw-ship.md
    bw-verify.md
    bw-work.md
  steering/
    philosophy.md

AGENTS.md               # canonical agent instructions (committed)
CLAUDE.md               # pointer stub → AGENTS.md (committed)
.claude/                # generated by make sync
.opencode/              # generated by make sync
.cursor/rules/          # generated by make sync
skills/                 # generated by make sync for Codex CLI
```

`.buildwright/` and `AGENTS.md` are canonical and committed. `CLAUDE.md` is a
pointer stub to `AGENTS.md`. Generated tool directories are gitignored.

## Development

After editing `.buildwright/`, run:

```bash
make sync
make sync-check
make validate
```

`make sync` regenerates tool-specific config, Codex skills, and the CLI README.
`AGENTS.md` and `CLAUDE.md` are hand-maintained root files, not generated.

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `BUILDWRIGHT_AGENT_RETRIES` | `2` | Verification retry count |
| `GITHUB_TOKEN` | unset | Used by `gh` when creating PRs |

Use a fine-grained GitHub token with contents and pull request permissions when
you want `/bw-ship` to push branches and create PRs.
