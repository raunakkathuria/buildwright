# Approve Intent, Ship Autonomously: Buildwright

Buildwright is a lightweight engineering discipline layer for agent-led
software work: understand, test, implement, document, verify, review, ship.

Every team using AI coding tools hits the same wall. The agent writes code
quickly, but humans still have to check whether it fits the codebase, updates
the docs, passes tests, handles security concerns, and is ready for review.
Buildwright turns that into a repeatable workflow.

## The Model

Buildwright keeps five commands:

| Command | When to use it |
|---------|----------------|
| `/bw-plan` | Think, research, or write a plan without code changes |
| `/bw-work` | Implement bug fixes, refactors, and features |
| `/bw-verify` | Run typecheck, lint, test, and build gates |
| `/bw-ship` | Security review, code review, push, and PR |
| `/bw-analyse` | Analyse an unfamiliar brownfield codebase |

The main implementation command is `/bw-work`.

```text
Understand -> Research -> Plan if needed -> Red -> Green -> Refactor -> Docs -> Verify -> Security -> Review -> Commit/Ship
```

Small changes stay lightweight. Larger features can still produce
`docs/specs/[feature]/research.md` and `spec.md`. Cross-domain changes use a
normal implementation plan instead of a separate multi-agent architecture.

## Documentation Is Part of Done

Teams often miss docs because they are treated as cleanup. Buildwright makes
them part of the workflow. Every feature, bug fix, command change, config
change, or public behavior change must update affected docs or explicitly state
why no docs apply.

## Steering

Buildwright installs one default steering file:

```text
.buildwright/steering/philosophy.md
```

That file captures KISS, YAGNI, DRY, boring technology, fail-fast behavior,
Red -> Green -> Refactor, documentation discipline, and financial-code rules.

Project-specific files such as `tech.md` and `product.md` are created only when
there is real project context. Placeholder steering files are not installed by
default.

## Tool-Agnostic Design

The canonical configuration lives in `.buildwright/`. `make sync` generates the
tool-specific directories used by Claude Code, OpenCode, Cursor, and Codex.

```text
.buildwright/
  agents/
  commands/
  steering/

.claude/
.opencode/
.cursor/rules/
skills/
```

Edit `.buildwright/`, run `make sync`, and the generated directories update.

## Try It

```bash
curl -sL https://raw.githubusercontent.com/raunakkathuria/buildwright/main/setup.sh | bash
```

Then run:

```text
/bw-work "Add user authentication with OAuth2"
```

For unfamiliar existing projects, run `/bw-analyse` first so future sessions
start with real codebase context.
