---
name: bw-work
version: 0.0.18
description: Implement bug fixes, refactors, and features with research, Red-Green-Refactor, docs, verification, security review, and code review
arguments:
  - name: task
    description: What to build, fix, or refactor
    required: true
---

# /bw-work

Use this for implementation work: bug fixes, refactors, small changes, and new
features. The command chooses the lightest workflow that still protects quality.

## Core Loop

```
Understand -> Research -> Plan if needed -> Red -> Green -> Refactor -> Docs -> Verify -> Security -> Review -> Commit/Ship
```

Always recursively discover and read all `.md` files under
`.buildwright/steering/`. Read `philosophy.md` first when present because it is
the default baseline. Also recursively read `.buildwright/codebase/*.md` if
that directory exists.

Follow `.buildwright/framework/autonomy.md` for the single autonomy behaviour and
auto-continue (work through ready, question-free items without per-item
re-invocation; pause only on a genuine decision). Prefer the host's native
capabilities per `.buildwright/framework/capability.md` — use native
task/todo tracking for the loop and native file writes rather than reimplementing
them in prose.

When you defer a decision (acceptable for staging, must fix before production) or
spot an issue better fixed upstream, record it per
`.buildwright/framework/findings.md` as it arises — don't leave it scattered.

## Phase 1: Understand

Parse `$ARGUMENTS.task` and identify:
- Work type: bug fix, feature, refactor, config/docs change
- Project state: greenfield or brownfield
- Scope: small/bounded or larger/unclear
- User-facing impact and documentation likely affected

If no project files exist, ask for product vision and constraints. Create
`.buildwright/steering/product.md` from the answer and create `tech.md` after
the stack and commands are chosen.

**If the task hands off a plan with an issue-ready breakdown** (per
`.buildwright/framework/tasks-to-issues.md`), create the tracked issues now,
before implementation: run the remote guard first, then create the parent and
one child per unit in its target repo, skipping any stable ID that already has
an issue. This handoff is the creation point the convention names - `/bw-plan`
prepares the breakdown but never creates issues.

## Phase 2: Command Discovery

If `.buildwright/steering/tech.md` exists and has real commands, use them.
Otherwise auto-detect from project files:

- `package.json` -> npm/pnpm/yarn/bun scripts
- `Cargo.toml` -> cargo
- `go.mod` -> go
- `pyproject.toml`, `setup.py`, `requirements.txt` -> Python tooling
- `Makefile` -> make targets

Derive typecheck, lint, test, build, and dev commands. Mark unavailable gates as
`SKIP`. Write a real `.buildwright/steering/tech.md` so future runs reuse the
discovery result. If detection is ambiguous, ask for the missing commands.

## Phase 3: Research

For small, clear tasks, do lightweight research in context:
- Read only directly relevant source files and tests
- Reuse existing functions, types, and patterns
- Check `.buildwright/codebase/CONVENTIONS.md` if present

For larger or unclear work, write:
- `docs/specs/[feature]/research.md`
- `docs/specs/[feature]/spec.md`

The spec must include scope, approach, risks, test strategy, documentation
impact, and implementation milestones. Follow the single autonomy behaviour
(`.buildwright/framework/autonomy.md`): proceed autonomously, pausing for approval
before implementation only when the approach involves a decision that is
genuinely the human's to make.

Cross-domain work still uses a normal spec and implementation plan. Do not use
legacy multi-agent terminology or domain-specialist personas.

## Phase 4: Implement with TDD

For every bug fix, behavior change, or feature milestone:

### Red

Write or update a failing test that describes the bug or expected behavior. Run
the focused test and confirm it fails for the right reason.

### Green

Make the smallest implementation that passes the test. Follow existing
patterns, reuse existing utilities, and avoid speculative abstractions.

### Refactor

Improve names, structure, duplication, and design while tests stay green. Keep
the scope tied to the current requirement.

## Phase 5: Documentation Check

Documentation is part of done. Before verification, update every affected
user-facing artifact:
- README or setup docs
- docs/ guides or API reference
- command/help text
- examples
- CHANGELOG, if the project uses one

If no documentation update is needed, record the reason in the final report.

## Phase 6: Verify

Run the discovered gates:
1. Typecheck
2. Lint
3. Test
4. Build

Skip only gates that are genuinely unavailable for the stack. If a required
gate fails, fix and re-run it. Keep going until the gate passes or you are no
longer making progress — the same failure recurs, or there is no diagnosable
fix. Do not loop indefinitely; on a stalled gate, hand off per the failure
behaviour.

## Phase 7: Security Review

Adopt the Security Engineer persona from `.buildwright/agents/security-engineer.md`
(or `~/.claude/agents/security-engineer.md` for a global install without a project
`.buildwright/`). Review the changed diff for:
- Secrets
- Dependency vulnerabilities, if tooling exists
- Input validation and authorization
- OWASP Top 10 risks
- Financial-code risks, especially floating point for currency

Stop on critical vulnerabilities.

## Phase 8: Code Review

Adopt the Staff Engineer persona from `.buildwright/agents/staff-engineer.md`
(or `~/.claude/agents/staff-engineer.md` for a global install without a project
`.buildwright/`). Review the changed diff for:
- Logic errors and missed edge cases
- Error handling
- Pattern fit and unnecessary complexity
- Missing tests
- Missing documentation updates

Fix blocking issues before committing.

## Phase 9: Commit or Ship

Use atomic conventional commits and stage only files changed for this work.

For small local work, commit and report the result. For PR-ready work, run
`/bw-ship` after verification, security, and review have passed. Verify,
security, and review just passed here — when `/bw-ship` runs next in the same run
and the working tree is unchanged, it reuses these results (its "Gate reuse"
rule) rather than re-running them. Report which gates passed and at what commit
so the reuse is unambiguous.

## Final Report

Report:
- Task and work type
- Files changed
- Tests and gates run
- Documentation updated, or why not applicable
- Commit hash or PR URL if created
