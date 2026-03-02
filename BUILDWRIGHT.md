# Buildwright Development Workflow

This project uses agent-first autonomous development.

## Quick Start

```bash
# After cloning, generate tool-specific configs from .buildwright/
make sync

# Then start your agent tool
claude

# For new features (full workflow)
> /bw-new-feature "Add user authentication"
> [Claude researches, generates spec, validates]
> approved
> [Claude implements and ships]

# For small tasks (fast path)
> /bw-quick "Fix the timeout bug"
> [Claude fixes, verifies, commits]
```

## The Flow

```
/bw-new-feature "description"
  │
  ├─ 0. DETECT: Greenfield? Ask product vision, suggest tech stack
  │
  ├─ 1. RESEARCH: Deep-read codebase, write research.md
  │
  ├─ 1.5 RESOLVE AMBIGUITIES: Identify gaps, auto-decide or ask
  │
  ├─ 2. PLAN: Generate spec with multi-approach analysis
  │
  ├─ 3. VALIDATE: Staff Engineer reviews spec (auto)
  │
  ├─ 4. APPROVE: Human says "approved" ◄── Only human step
  │             (For greenfield: also confirms tech stack)
  │
  ├─ 5. BUILD: TDD per milestone (uses patterns from research)
  │
  └─ 6. SHIP: verify → security → review → release


/bw-quick "task"  ◄── Fast path for small tasks
  │
  ├─ Quick research (in-context)
  ├─ Implement with TDD
  ├─ Verify
  └─ Commit
```

## Greenfield Projects

For new projects, Buildwright:
1. Asks ONE question: "What's the product vision?"
2. Infers appropriate tech stack from feature + product type
3. Generates steering docs (product.md, tech.md)
4. Presents suggested stack at approval time

```
Reply "approved" to proceed with this stack.
Or adjust: "approved, but use Vue instead of React"
```

## Autonomous Mode

For fully autonomous operation without human approval:

```bash
# Set environment variable
export BUILDWRIGHT_AUTO_APPROVE=true

# Or pass as argument
/bw-new-feature "Add feature" --auto-approve
```

**What changes:**
- Spec is still generated and validated by Staff Engineer
- All documents committed to git BEFORE implementation (audit trail)
- No human approval required — proceeds directly to BUILD
- Full traceability preserved in version control

**Audit trail commit:**
```
docs(spec): add specification for user-auth

- research.md: codebase analysis
- spec.md: implementation plan  
- Validated by Staff Engineer agent

Auto-approved: BUILDWRIGHT_AUTO_APPROVE=true
```

## Commands

| Command | Purpose |
|---------|---------|
| `/bw-new-feature` | Full pipeline: research → spec → approve → build → ship |
| `/bw-quick` | Fast path for bug fixes, small tasks |
| `/bw-ship` | Quality gates + release: verify → security → review → push → PR |
| `/bw-verify` | Quick checks: typecheck, lint, test, build |
| `/bw-help` | Show available commands |

## When to Use Each

| Scenario | Command |
|----------|---------|
| New feature | `/bw-new-feature` |
| Bug fix | `/bw-quick` |
| Small task (<2 hrs) | `/bw-quick` |
| Greenfield project | `/bw-new-feature` (auto-detected) |

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `BUILDWRIGHT_AUTO_APPROVE` | `true` | Autonomous mode — skip human approval, fail gracefully on errors |
| `BUILDWRIGHT_AGENT_RETRIES` | `2` | Number of verify retries before giving up |

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

**Interactive failure path**: STOP and report blocker (current behavior, unchanged).

### PR Failure Summary Template

When the autonomous pipeline fails, the PR body uses this format:

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

Security and review findings are classified by severity:

| Severity | Action | Example |
|----------|--------|---------|
| **Critical / High** | Block — must fix before merge | SQL injection, exposed secrets, auth bypass |
| **Medium** | Fix in this PR if feasible, otherwise track | Missing rate limiting, verbose error messages |
| **Low / Info** | Advisory — log and move on | Minor header hardening, informational findings |

Only Critical/High findings block the pipeline. Medium and Low findings are reported but don't prevent shipping.

## Agent Personas

| Agent | Purpose | Key Capabilities | Location |
|-------|---------|-------------------|----------|
| Staff Engineer | Spec & code review | Confidence scoring (≥80), HIGH SIGNAL criteria, false-positive exclusions | `.buildwright/agents/staff-engineer.md` |
| Security Engineer | Security review | Confidence scoring (≥0.8), exploit scenarios, hard exclusions | `.buildwright/agents/bw-security-engineer.md` |

## Customization

- **Product context**: `.buildwright/steering/product.md`
- **Tech stack**: `.buildwright/steering/tech.md`
- **Quality gates**: `.buildwright/steering/quality-gates.md`
- **Learned patterns**: `CLAUDE.md` (bottom section)
