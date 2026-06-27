<!--
SYNC IMPACT REPORT
==================
Version change: 1.1.0 → 1.2.0
Bump rationale (1.2.0): Principles I (Agent-First Autonomy) and III (Verification
  Before Commit) amended to retire the unenforced `BUILDWRIGHT_AGENT_RETRIES`
  count in favour of a progress-based stop condition (fix and re-run until the
  gate passes or progress stalls). Materially changed guidance → MINOR.
Bump rationale (1.1.0): Principle I (Agent-First Autonomy) amended to retire the
  legacy auto-approve mode flag in favour of a single autonomy behaviour with
  context-inferred failure handling (feature 001-buildwright-workflow-improvements,
  FR-015). Materially changed guidance → MINOR.
Bump rationale (1.0.0): Initial ratification — first concrete fill of the
  constitution template with Buildwright's governing principles. MAJOR baseline.

Modified principles (placeholder → concrete):
  [PRINCIPLE_1_NAME] → I. Agent-First Autonomy
  [PRINCIPLE_2_NAME] → II. Test-First Discipline (NON-NEGOTIABLE)
  [PRINCIPLE_3_NAME] → III. Verification Before Commit
  [PRINCIPLE_4_NAME] → IV. Documentation Is Part of Done
  [PRINCIPLE_5_NAME] → V. Simplicity & Boring Technology

Added sections:
  [SECTION_2_NAME]  → Additional Constraints
  [SECTION_3_NAME]  → Development Workflow

Removed sections: none

Templates requiring updates:
  ✅ .specify/templates/plan-template.md — Constitution Check gates filled
  ✅ .specify/templates/constitution-template.md — source template (unchanged; kept)
  ✅ .specify/templates/tasks-template.md — "Tests are OPTIONAL" language replaced
     with Principle II framing: tests REQUIRED for behavior changes (Red→Green→
     Refactor), omitted only for non-behavior tasks (setup, config, docs, covered
     refactors).
  ✅ .specify/templates/spec-template.md — no constitution-specific conflicts
  ✅ AGENTS.md — already the canonical source of these principles; aligned

Follow-up TODOs: none
-->

# Buildwright Constitution

## Core Principles

### I. Agent-First Autonomy

Agents execute autonomously and own the full loop: understand, test, implement,
document, verify, review, and ship. Humans approve intent only when information
is genuinely missing or a decision is theirs to make. Agents MUST verify their
own work through tests and checks rather than assuming success, and MUST stop
only when genuinely blocked.

There is one autonomy behaviour, governed by no mode flag. On a step failing
after retries are exhausted — the agent is no longer making progress — the agent
MUST infer the execution context: in an interactive session it MUST stop and report the
blocker; in an unattended/headless run (CI, no TTY) it MUST commit completed
work, push, open a PR with failure details, and exit non-zero. If context cannot
be determined, it MUST default to the unattended behaviour.

**Rationale**: The framework exists to make disciplined development run without
constant human babysitting; autonomy without self-verification is just
unchecked output.

### II. Test-First Discipline (NON-NEGOTIABLE)

All behavior changes MUST follow Red → Green → Refactor.

- **Red**: Write a failing test that reproduces the bug or describes the
  expected behavior.
- **Green**: Write the smallest implementation that makes the test pass.
- **Refactor**: Improve names, structure, duplication, and design while tests
  stay green.

**Rationale**: Tests written after the fact validate what was built, not what
was intended. Red-first proves the test can fail and the fix is what made it
pass.

### III. Verification Before Commit

Before every commit, the discovered quality gates MUST run and pass:

1. Typecheck
2. Lint
3. Test
4. Build

Only gates that are genuinely unavailable for the stack may be skipped, and the
skip MUST be reported. A required gate that fails MUST be fixed and retried until
it passes or progress stalls — the same failure recurs, or there is no
diagnosable fix — before the work item is treated as failed.

**Rationale**: A green local gate is the cheapest place to catch a regression;
committing past a red gate exports the failure to everyone downstream.

### IV. Documentation Is Part of Done

Documentation is not a follow-up task. Every feature, bug fix, behavior change,
command change, config change, or public workflow change MUST update affected
documentation in the same work item: README, docs, command text, examples, API
docs, changelog, or generated user-facing docs. If no docs need updating, the
final report MUST state why.

**Rationale**: Documentation deferred is documentation never written; drift
between behavior and docs erodes trust in both.

### V. Simplicity & Boring Technology

- **KISS**: Prefer the simplest readable solution that solves the current need.
- **YAGNI**: Do not add speculative features, extension points, or abstractions.
- **DRY**: Search for existing functions, types, utilities, and docs before
  creating new ones.
- **Boring technology**: Prefer proven tools and project-local patterns.
- **Fail fast**: Validate inputs at boundaries and surface clear errors.
- **No premature optimization**: Make it correct first; optimize with evidence.

**Rationale**: Complexity is the dominant long-term cost of software; defaulting
to simple, proven choices keeps the system understandable and changeable.

## Additional Constraints

**Single source of truth**: `.buildwright/` and the root `AGENTS.md` are the
canonical, committed configuration. Tool-specific directories (`.claude/`,
`.opencode/`, `.cursor/rules/`, `skills/`) are generated by `make sync` and MUST
NOT be committed. After editing `.buildwright/`, `make sync` MUST be run before
committing.

**Git discipline**:
- Atomic commits — only commit files you changed.
- Conventional commit prefixes: `feat:`, `fix:`, `refactor:`, `test:`,
  `docs:`, `chore:`.
- Never edit `.env` files.
- Never run destructive git operations without explicit instruction.
- Never use `git stash`.

**Financial code**: Use Decimal, BigDecimal, integer minor units, or the
project-approved money type for currency and trading calculations. Floating
point MUST NOT be used for money.

**Code standards**: Follow existing patterns exactly. Keep files focused and
readable. Validate user input at boundaries. Avoid type-system escape hatches
unless the project already requires them.

## Development Workflow

Use the smallest command that matches the intent:

1. `/bw-plan` — think and research only; no code changes, commits, or PRs.
2. `/bw-work` — implement bug fixes, refactors, and features (TDD applies).
3. `/bw-verify` — run typecheck, lint, test, and build gates.
4. `/bw-ship` — verify, then security review, code review, push, and PR.
5. `/bw-analyse` — analyse brownfield codebases and write `.buildwright/codebase/`
   docs.

**Steering**: At the start of every session, recursively read all `.md` files
under `.buildwright/steering/` (default `philosophy.md`) and, if present,
`.buildwright/codebase/`.

**Quality gates for shipping**: `/bw-ship` MUST pass verification (Principle
III), a security review, and a code review before pushing and opening a PR. It
fails fast if any step fails.

## Governance

This constitution supersedes other development practices in conflict with it.

**Amendments**: Changes to this constitution MUST be documented in the Sync
Impact Report at the top of this file, with a version bump and propagation to
dependent templates (`plan-template.md`, `spec-template.md`, `tasks-template.md`)
and runtime guidance (`AGENTS.md`).

**Versioning policy** (semantic):
- **MAJOR**: Backward-incompatible governance or principle removals/redefinitions.
- **MINOR**: A new principle or section, or materially expanded guidance.
- **PATCH**: Clarifications, wording, and non-semantic refinements.

**Compliance**: Every `/bw-work` and `/bw-ship` run is expected to comply with
these principles. Code review and security review under `/bw-ship` MUST verify
compliance. Any complexity that violates Principle V MUST be justified in the
plan's Complexity Tracking table.

**Version**: 1.2.0 | **Ratified**: 2026-06-27 | **Last Amended**: 2026-06-28
