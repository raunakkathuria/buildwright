---
name: buildwright
description: Lightweight engineering workflow for agent-led development. Provides plan, work, verify, ship, and analyse commands with TDD, documentation discipline, security review, code review, and quality gates.
license: MIT
compatibility: Requires git and gh for shipping. Optional tools for security scans include semgrep, gitleaks, and trufflehog. Works with Claude Code, OpenCode, Cursor, and Codex CLI.
metadata:
  homepage: https://github.com/raunakkathuria/buildwright
  version: "0.0.16"
  author: raunakkathuria
  tags:
    - development
    - workflow
    - tdd
    - security
    - code-review
    - documentation
---

# Buildwright

Buildwright is a lightweight engineering discipline layer: understand, test,
implement, document, verify, review, ship.

## Commands

### /bw-work

Implement bug fixes, refactors, and features.

Flow: understand -> research -> plan if needed -> Red -> Green -> Refactor ->
docs -> verify -> security review -> code review -> commit/ship.

For larger features, `/bw-work` writes `docs/specs/[feature]/research.md` and
`docs/specs/[feature]/spec.md`. For small tasks, it keeps research lightweight.
Every user-facing change must update affected docs or state why no docs apply.

### /bw-plan

Research a question or topic and produce a written deliverable. No source
changes, commits, pushes, or PRs.

### /bw-verify

Run project quality gates: typecheck, lint, test, and build. Commands come from
`.buildwright/steering/tech.md` when present; otherwise Buildwright detects and
writes them.

### /bw-ship

Run verify, security review, Staff Engineer review, then commit, push, and open
a PR. Shipping confirms documentation was updated or explicitly not applicable.

### /bw-analyse

Analyse a brownfield codebase and write `.buildwright/codebase/STACK.md`,
`ARCHITECTURE.md`, `CONVENTIONS.md`, and `CONCERNS.md`. Also creates or updates
`.buildwright/steering/tech.md` with discovered stack and commands.

## Steering

Buildwright recursively reads every `.md` file under `.buildwright/steering/`.
It installs one default steering file:

- `.buildwright/steering/philosophy.md` — KISS, YAGNI, DRY, boring technology,
  fail fast, Red -> Green -> Refactor, documentation discipline, and financial
  code rules.

Project-specific steering is lazy-created:

- `tech.md` after command and stack discovery.
- `product.md` only for greenfield work or explicit product context.

## Personas

Buildwright uses prompt-based review personas:

- Staff Engineer for spec/code review.
- Security Engineer for security review.

## Safety

Buildwright does not edit `.env` files, run destructive git operations, force
push, or merge PRs. It stages only files changed for the current work.
