---
name: buildwright
description: Autonomous development workflow with multi-agent Claw Architecture. Single-agent mode for simple features; multi-agent mode decomposes cross-domain work into specialist claws (UI, API, DB). Includes TDD, security scan, code review, and quality gates. Works with Claude Code, OpenCode, OpenClaw, and Cursor.
license: MIT
compatibility: Requires git and gh (GitHub CLI). GITHUB_TOKEN with repo scope needed for push/PR. Optional tools for security scans (semgrep, gitleaks, trufflehog). Works with Claude Code, OpenCode, OpenClaw, and Cursor.
metadata:
  homepage: https://github.com/raunakkathuria/buildwright
  version: "0.0.3"
  author: raunakkathuria
  tags:
    - development
    - workflow
    - tdd
    - security
    - code-review
    - autonomous
    - multi-agent
    - claw-architecture
  openclaw:
    requires:
      bins:
        - git
        - gh
      env:
        - GITHUB_TOKEN
    primaryEnv: GITHUB_TOKEN
---

# Buildwright

Spec-driven autonomous development. Humans approve intent; agents handle everything else.

## What this skill does

When activated, Buildwright directs the agent to:

1. Read your codebase and steering documents
2. Write a one-page spec (`docs/specs/[feature]/spec.md`)
3. Stop for human approval — unless `BUILDWRIGHT_AUTO_APPROVE=true`
4. Implement the feature with TDD
5. Run quality gates: typecheck, lint, test, build
6. Run optional security scans (if semgrep / gitleaks / trufflehog are installed)
7. Run a Staff Engineer prompt-based code review
8. Commit, push, and open a PR via `gh`

## Requirements

### Credentials (required)

| Credential | Purpose | Scope | How to provide |
|------------|---------|-------|----------------|
| `GITHUB_TOKEN` | Push commits and open PRs via `gh` | `repo` scope (read/write) | `export GITHUB_TOKEN=ghp_...` or configure in OpenClaw config under `skills.entries.buildwright.apiKey` |

The token must have `repo` scope to push branches and create pull requests. For minimal privilege, use a fine-grained personal access token scoped to a single repository with "Contents: Read and write" and "Pull requests: Read and write" permissions.

Alternatively, if you use SSH for git push, the `GITHUB_TOKEN` is still needed for `gh pr create`. You can use `gh auth login` to authenticate the GitHub CLI separately.

### Binaries (required)

| Binary | Purpose |
|--------|---------|
| `git` | Commits and pushes |
| `gh` | Opens PRs via GitHub CLI |

### Optional tools

| Binary | Purpose |
|--------|---------|
| `semgrep` | SAST security scan |
| `gitleaks` / `trufflehog` | Secrets detection |

## Agent Personas (prompt-based, no binaries)

**Staff Engineer** and **Security Engineer** are prompt-engineering personas — instructions loaded from `.buildwright/agents/` files in the workspace. They are not external tools or binaries. The agent adopts these personas to review specs and code using defined criteria and confidence thresholds. These files contain only prompt instructions and review checklists — no secrets or credentials.

## Configuration

### BUILDWRIGHT_AUTO_APPROVE (optional, not a credential)

This is an optional boolean flag that controls whether the agent waits for human approval at the spec stage. It is **not** a secret and **not** declared in `requires.env` because it is not required to run the skill.

| Value | Behavior |
|-------|---------|
| Not set | **Interactive** (default) — stops and waits for "approved" before building |
| `false` | Interactive — same as default |
| `true` | **Autonomous** — commits spec to git (audit trail) and proceeds without waiting |

**Recommendation for first use:** Leave `BUILDWRIGHT_AUTO_APPROVE` unset until you have reviewed a few specs and are comfortable with the workflow. Start with interactive mode in a sandbox repository to observe behavior before enabling autonomous commits and PRs.

## Commands

### /bw-new-feature \<description\>

Full pipeline for new features. Auto-detects greenfield vs existing projects.

```
/bw-new-feature "Add OAuth2 login"
```

Flow: Detect (greenfield or existing?) → Research → Spec → Staff Engineer validates → Human approves → TDD build → Verify → Security scan → Code review → PR

**Artifacts produced:**
- `docs/specs/[feature]/research.md` — what the agent found in your codebase
- `docs/specs/[feature]/spec.md` — implementation plan with approaches considered

---

### /bw-claw \<feature\>

Multi-agent pipeline using the Claw Architecture. Architect decomposes the feature into domain-specific claw tasks (UI, API, DB), defines interface contracts, and coordinates execution.

```
/bw-claw "Add profile photo upload for team members"
```

Flow: Architect analyzes → Decomposes into claw tasks → Defines interface contract → Claws execute per domain (TDD) → Architect integrates → Buildwright quality gates → PR

**Best for:** Features that cross domain boundaries (e.g., need DB schema + API endpoint + UI component).

**Artifacts produced:**
- `docs/specs/[feature]/claw-plan.md` — decomposition plan with interface contracts
- `docs/specs/[feature]/claw-[domain].md` — per-claw execution report

---

### /bw-quick \<task\>

Fast path for bug fixes and small tasks (<2 hrs). No spec, no approval step.

```
/bw-quick "Fix the login timeout bug"
```

---

### /bw-ship \[message\]

Quality pipeline for existing work: verify → security → review → PR.

```
/bw-ship "feat(auth): add OAuth2 support"
```

---

### /bw-verify

Quick checks only: typecheck → lint → test → build.

---

### /bw-analyse

Analyse an existing codebase and write structured docs to `.buildwright/codebase/`. Updates `tech.md` with the discovered stack and commands. Run this first on any brownfield project to give every subsequent session real context.

```
/bw-analyse
```

Produces: `STACK.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`, `CONCERNS.md` under `.buildwright/codebase/`.

---

### /bw-help

Show all available commands.

---

## Failure Behavior

If any gate fails after retries, the agent commits completed work, pushes, and opens a PR with a structured failure report. It does not leave orphaned branches or silent failures.

## Retry Policy

| Gate | Retries | Rationale |
|------|---------|-----------|
| Verify (typecheck, lint, test, build) | 2x | Fixable by the agent |
| Security scan | None | Requires human judgment |
| Code review | None | Architectural decisions need humans |

## Security Considerations

This skill performs autonomous code changes, commits, and pull requests. Understand what it does before enabling it on repositories with sensitive or production code.

**What the skill reads:** Your repository source code, `.buildwright/agents/` persona files (prompt instructions only, no secrets), and `.buildwright/steering/` context files.

**What the skill writes:** Spec files under `docs/specs/`, source code changes, git commits on feature branches, and pull requests via `gh`.

**What the skill does NOT do:** It does not modify `.env` files, access secrets stores, run destructive git operations (force push, reset), or merge PRs. All changes go to feature branches with PRs for human review.

**Recommended setup for first use:**

1. Start with a fork or sandbox repository, not production code
2. Leave `BUILDWRIGHT_AUTO_APPROVE` unset (interactive mode) to review specs before builds
3. Use a fine-grained GitHub token scoped to a single repository with minimal permissions
4. Rotate tokens regularly and revoke when no longer needed
5. Review generated PRs before merging — the skill creates PRs, it does not merge them

## More Information

Full documentation, source code, and setup instructions: https://github.com/raunakkathuria/buildwright
