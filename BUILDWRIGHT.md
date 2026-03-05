# Buildwright Development Workflow

This project uses agent-first autonomous development. See [README.md](README.md) for full setup, concepts, and workflow details.

## Quick Start

```bash
# After cloning, generate tool-specific configs from .buildwright/
make sync

# Install git hooks to auto-sync on .buildwright/ changes
make install-hooks

# Start your agent tool
claude
```

## Commands

| Command | Purpose |
|---------|---------|
| `/bw-new-feature` | Full pipeline: research → spec → approve → build → ship |
| `/bw-quick` | Fast path for bug fixes, small tasks |
| `/bw-claw` | Cross-domain features: Architect decomposes → claws execute per domain → integrate → ship |
| `/bw-ship` | Quality gates + release: verify → security → review → push → PR |
| `/bw-verify` | Quick checks: typecheck, lint, test, build |
| `/bw-analyse` | Analyse existing codebase → write structured docs to `.buildwright/codebase/` → update tech.md |
| `/bw-help` | Show available commands |

## Environment Variables

| Variable | Default | Required | Purpose |
|----------|---------|----------|---------|
| `GITHUB_TOKEN` | — | Yes | Push branches and open PRs via `gh`. Needs `repo` scope. |
| `BUILDWRIGHT_AUTO_APPROVE` | `true` | No | Autonomous mode — skip human approval, fail gracefully on errors |
| `BUILDWRIGHT_AGENT_RETRIES` | `2` | No | Number of verify retries before giving up |

## Failure Behavior

| Mode | Any Failure | Behavior |
|------|-------------|----------|
| Autonomous (`BUILDWRIGHT_AUTO_APPROVE=true`, default) | Commit + push + failed PR + exit(1) | CI/CD fails, PR shows failure details |
| Interactive (`BUILDWRIGHT_AUTO_APPROVE=false`) | STOP, show error | Human fixes in-session |

**Autonomous failure path** (verify retries exhausted / critical security / review blocked):
1. Commit all completed work to feature branch
2. Push branch
3. Create PR with failure summary (see template below)
4. Exit with error code (pipeline fails in CI/CD)

**Interactive failure path**: STOP and report blocker.

### PR Failure Summary Template

```markdown
## BUILDWRIGHT: Pipeline Failed

**Feature:** [name]
**Mode:** Autonomous
**Failed at:** [Verify / Security / Review]
**Reason:** [Retries exhausted / Critical vulnerability / Changes requested]

### Pipeline Status
| Step | Status | Details |
|------|--------|---------|
| Verify | [pass/fail] | [details] |
| Security | [pass/fail/skipped] | [details] |
| Review | [pass/fail/skipped] | [details] |

### Completed Work
- [list of completed milestones/steps]

### Failure Details
- [error summary, specific findings, or review feedback]

### Skipped
- [steps that were blocked by the failure]

### To Resume
Fix the issue on this branch, then re-run the relevant command.
```

## Severity Triage

| Severity | Action | Example |
|----------|--------|---------|
| **Critical / High** | Block — must fix before merge | SQL injection, exposed secrets, auth bypass |
| **Medium** | Fix in this PR if feasible, otherwise track | Missing rate limiting, verbose error messages |
| **Low / Info** | Advisory — log and move on | Minor header hardening, informational findings |

Only Critical/High findings block the pipeline. Medium and Low findings are reported but don't prevent shipping.

## Agent Personas

| Agent | File | Purpose |
|-------|------|---------|
| Staff Engineer | `.buildwright/agents/staff-engineer.md` | Spec & code review, confidence scoring (≥80) |
| Security Engineer | `.buildwright/agents/security-engineer.md` | Security review, exploit scenarios, hard exclusions |
| Architect | `.buildwright/agents/architect.md` | Claw Architecture — decomposes cross-domain features |
