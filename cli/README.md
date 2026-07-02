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

## Framework behavior vs. steering

Buildwright separates **how the framework operates** from **your project's
choices**.

**Framework behavior** lives in `.buildwright/framework/`. It is Buildwright-owned
and fixed — identical in every install, refreshed on update, not meant to be
customized:

```text
.buildwright/framework/autonomy.md    # the single autonomy behaviour, auto-continue, context-inferred failure handling
.buildwright/framework/capability.md  # prefer host-native capabilities (plan/file-write/tasks/subagents/hooks) with fallbacks
.buildwright/framework/findings.md    # convention for report-upstream and before-production deferrals
```

`autonomy.md` is why there is no approval flag — one behaviour, inferred from
context. `capability.md` keeps commands leaning on each host tool's built-ins
(parallelism, task tracking, sub-agents, worktrees, file-write, hooks) for
*execution mechanics* — they never replace Buildwright's steering or process.
`findings.md` standardises how deferred decisions are recorded.

**Steering** lives in `.buildwright/steering/`. It is project-owned and
customizable, and is preserved across updates:

```text
.buildwright/steering/philosophy.md   # KISS, YAGNI, DRY, fail-fast, TDD, docs, financial-code rules (shipped default; customizable)
```

`philosophy.md` defines the engineering principles; ship a default and customize
it per project. Further project-specific steering is created only when there is
real content:

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

`buildwright update` refreshes Buildwright commands, agents, framework behavior,
default steering, and Buildwright-owned support scripts (now under
`.buildwright/scripts/`). It also removes paths from superseded layouts: the old
`.buildwright/steering/` locations of the framework docs, and the pre-0.0.18
root-level `scripts/` and Buildwright-shipped `Makefile` (anything you
customized is left in place). In a consuming project there is no Buildwright
Makefile anymore — run `buildwright sync` or
`bash .buildwright/scripts/sync-agents.sh` instead of `make sync`.

Framework files (`.buildwright/framework/`) are Buildwright-owned and always
refreshed to the shipped version — do not customize them.

Steering is treated differently: it is only touched if Buildwright ships the
file. The default `philosophy.md` is refreshed in place only when it is
unmodified (a known shipped version); a customized `philosophy.md` is preserved.
Any steering file Buildwright does not ship — your `tech.md`, `product.md`, or
org-injected docs such as `quality-gates.md` — is never deleted or overwritten.

### From Source

```bash
git clone https://github.com/raunakkathuria/buildwright.git
cd buildwright
make sync
```

Per-project `buildwright init` is the single supported install — it commits the
workflow config to your repo so it is versioned and shared with your team, and
the generated tool configs (Claude Code, OpenCode, Cursor, Codex) come from the
same `.buildwright/` source of truth.

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
  framework/              # Buildwright-owned, refreshed on update
    autonomy.md
    capability.md
    findings.md
    tasks-to-issues.md
  scripts/                # Buildwright-owned support scripts, refreshed on update
    sync-agents.sh        # regenerates the tool configs below
    validate-docs.sh
    install-hooks.sh
    hooks/                # git hooks: auto-sync on commit/merge/checkout
  steering/               # project-owned, preserved on update
    philosophy.md

AGENTS.md               # canonical agent instructions (committed)
CLAUDE.md               # pointer stub → AGENTS.md (committed)
.claude/                # generated by sync (gitignored)
.opencode/              # generated by sync (gitignored)
.cursor/rules/          # generated by sync (gitignored)
skills/                 # generated by sync for Codex CLI (gitignored)
```

`.buildwright/` and `AGENTS.md` are canonical and committed. `CLAUDE.md` is a
pointer stub to `AGENTS.md`. Generated tool directories are gitignored.

## Development

After editing `.buildwright/`, run:

```bash
make sync
make sync-check
```

`make sync` regenerates tool-specific config, Codex skills, and the CLI README.
`AGENTS.md` and `CLAUDE.md` are hand-maintained root files, not generated.

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `GITHUB_TOKEN` | unset | Used by `gh` when creating PRs |

Use a fine-grained GitHub token with contents and pull request permissions when
you want `/bw-ship` to push branches and create PRs.
