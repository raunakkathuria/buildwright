---
name: bw-quick
description: Fast path for ad-hoc tasks (bug fixes, small features, config changes) without full planning
arguments:
  - name: task
    description: What to do (inline description)
    required: true
---

## Quick Mode

Fast path for ad-hoc tasks that don't need full planning.

**Use for:**
- Bug fixes
- Small features (< 2 hours)
- Config changes
- One-off tasks
- Refactors with clear scope

**Don't use for:**
- New features with unclear scope
- Changes touching multiple systems
- Anything needing architectural decisions

```
┌─────────────────────────────────────────────────────────────┐
│                      QUICK MODE                             │
├─────────────────────────────────────────────────────────────┤
│  1. Understand task                                         │
│  2. Quick research (relevant files only)                    │
│  3. Implement with TDD                                      │
│  4. Verify (typecheck, lint, test, build)                   │
│  5. Security (OWASP + secrets + dependencies)               │
│  6. Code Review (Staff Engineer)                            │
│  7. Commit                                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 1: Understand Task

**First, run Tech Discovery Protocol** (Command Discovery in CLAUDE.md) to determine the project's
test, lint, typecheck, and build commands. Cache the result for subsequent steps.

If no project files are found (greenfield — no `package.json`, `Cargo.toml`, `go.mod`, etc.),
ask for the product vision before proceeding. Quick tasks on a blank project need context.

Parse: $ARGUMENTS.task

Identify:
- What needs to change
- Why (bug, feature, refactor)
- Expected outcome
- Scope boundaries

If scope is unclear or large, recommend:
```
This task seems complex. Consider using /bw-new-feature instead for:
• Proper research phase
• Technical specification
• Staff Engineer review

Continue with /bw-quick anyway? (say "continue" or use /bw-new-feature)
```

---

## Step 2: Quick Research

**Lightweight research - only what's needed for this task.**

**First, check for pre-analysed codebase docs:**

```bash
ls .buildwright/codebase/ 2>/dev/null
```

If present, read `CONVENTIONS.md` and `ARCHITECTURE.md` — they give you naming patterns
and layer boundaries without scanning the whole codebase. Check `CONCERNS.md` to avoid
introducing more of the same issues. Then narrow your search to the specific files for
this task.

```bash
# Find directly relevant files
grep -r "[relevant terms]" --include="*.ts" --include="*.tsx" -l .

# Read the specific files that will change
cat [files to modify]

# Check for existing tests
find . -name "*.test.*" -o -name "*.spec.*" | xargs grep -l "[relevant terms]"
```

Understand:
- Current implementation
- Patterns used in these files
- Related tests

**Do NOT write a research document. Keep it in context.**

---

## Step 3: Implement with TDD

### 3.1 Write/Update Tests First

If bug fix:
```bash
# Write a failing test that reproduces the bug
```

If feature:
```bash
# Write tests for the expected behavior
```

Commit: `test: add test for [task]`

### 3.2 Implement

- Fix the bug / add the feature
- Follow existing patterns in the file
- Minimal changes only
- KISS, YAGNI

### 3.3 Update Documentation

Based on what you just implemented, identify which documentation files are affected and update them.

Common candidates:
- **README.md** — new behaviour, changed commands, updated flags, usage examples
- **docs/** — any guides or reference covering the changed functionality
- **CHANGELOG.md** — add an entry for any user-facing change

State up front which files you will update (e.g. "Updating README.md: correcting pipeline steps").
Skip entirely if nothing user-facing changed (internal refactor, test-only changes).

If docs were updated, commit them separately before the next step:
```bash
git add [doc files]
git commit -m "docs: update documentation for [task]"
```

### 3.4 Verify (with retry)

```bash
# Run project's verification commands
[typecheck]
[lint]
[test]
[build]
```

- If fails → Fix and retry (up to BUILDWRIGHT_AGENT_RETRIES attempts, default 2)
- If same error repeats → Not making progress — handle failure (see below)
- If still failing after retries → Handle failure:
  - **Autonomous** (`BUILDWRIGHT_AUTO_APPROVE=true`, default): Commit completed work, push branch, exit(1). No PR for quick tasks.
  - **Interactive** (`BUILDWRIGHT_AUTO_APPROVE=false`): STOP and report blocker.

### 3.5 Security Review

Adopt Security Engineer persona from `.buildwright/agents/security-engineer.md`.

Scope: `git diff HEAD` (uncommitted changes only).

Run automated scans:
- Dependency vulnerabilities (stack-appropriate audit tool) — skip gracefully if unavailable
- Secrets detection (pattern scan for API keys, passwords, tokens, private keys)
- SAST (`semgrep --config p/owasp-top-ten .` if available — skip gracefully if unavailable)

Then perform manual OWASP Top 10 review of changed files only.

**If CRITICAL vulnerabilities found → Handle failure:**
- **Autonomous** (`BUILDWRIGHT_AUTO_APPROVE=true`, default): Commit completed work, push branch, exit(1).
- **Interactive** (`BUILDWRIGHT_AUTO_APPROVE=false`): STOP immediately.

```
╔═══════════════════════════════════════════════════════════════╗
║  SECURITY                                                     ║
╠═══════════════════════════════════════════════════════════════╣
║  Dependencies:  ✅/❌  ([N] vulnerabilities)                   ║
║  Secrets:       ✅/❌  ([N] found)                             ║
║  OWASP Scan:    ✅/❌  ([N] issues)                            ║
╠═══════════════════════════════════════════════════════════════╣
║  Status: SECURE / CRITICAL VULNERABILITIES                    ║
╚═══════════════════════════════════════════════════════════════╝
```

---

### 3.6 Code Review

Adopt Staff Engineer persona from `.buildwright/agents/staff-engineer.md`.

Scope: `git diff HEAD` (same diff as security step).

Review changed code for:
- Logic errors and edge cases
- Error handling completeness
- Missing validation at system boundaries
- Unnecessary complexity introduced

**If CHANGES REQUESTED → Handle failure:**
- **Autonomous** (`BUILDWRIGHT_AUTO_APPROVE=true`, default): Commit completed work, push branch, exit(1).
- **Interactive** (`BUILDWRIGHT_AUTO_APPROVE=false`): STOP immediately.

```
╔═══════════════════════════════════════════════════════════════╗
║  CODE REVIEW                                                  ║
╠═══════════════════════════════════════════════════════════════╣
║  Logic:          ✅/❌                                         ║
║  Error Handling: ✅/❌                                         ║
║  Validation:     ✅/❌                                         ║
╠═══════════════════════════════════════════════════════════════╣
║  Status: APPROVED / CHANGES REQUESTED                         ║
╚═══════════════════════════════════════════════════════════════╝
```

---

### 3.7 Commit

```bash
git add [changed files]
git commit -m "[type]([scope]): [description]"
```

Commit types:
- `fix:` for bug fixes
- `feat:` for small features
- `refactor:` for refactors
- `chore:` for config/maintenance

---

## Step 4: Report

```
╔═══════════════════════════════════════════════════════════════╗
║                      QUICK TASK COMPLETE                      ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Task: [description]                                          ║
║  Type: [bug fix / feature / refactor / chore]                 ║
║                                                               ║
║  Changes:                                                     ║
║  • [file1]: [what changed]                                    ║
║  • [file2]: [what changed]                                    ║
║                                                               ║
║  Verification:                                                ║
║  ✅ Type Check                                                ║
║  ✅ Lint                                                      ║
║  ✅ Tests                                                     ║
║  ✅ Build                                                     ║
║  ✅ Security                                                  ║
║  ✅ Code Review                                               ║
║                                                               ║
║  Commit: [hash] [message]                                     ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Ready to push? Run: git push                                 ║
║  Or run /bw-ship to push + open PR                              ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## When to Escalate

If during implementation you discover:
- Task is larger than expected
- Changes needed in multiple systems
- Architectural decisions required
- Unclear requirements

**STOP and recommend:**

```
╔═══════════════════════════════════════════════════════════════╗
║                    SCOPE ESCALATION                           ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  This task is more complex than expected:                     ║
║  • [Reason 1]                                                 ║
║  • [Reason 2]                                                 ║
║                                                               ║
║  Recommendation: Use /bw-new-feature for proper planning         ║
║                                                               ║
║  /bw-new-feature "[task description with discovered context]"    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## Examples

### Bug Fix
```
/bw-quick "Fix login timeout - session expires after 5 minutes instead of 30"
```

### Small Feature
```
/bw-quick "Add loading spinner to the submit button"
```

### Config Change
```
/bw-quick "Increase rate limit from 100 to 500 requests per minute"
```

### Refactor
```
/bw-quick "Extract the validation logic from UserForm into a separate hook"
```

---

## Difference from /bw-new-feature

| Aspect | /bw-quick | /bw-new-feature |
|--------|--------|--------------|
| Research | Quick (in-context) | Full (research.md) |
| Spec | None | Full spec.md |
| Staff Engineer Review | Required (diff-scoped) | Spec + Code |
| Security Review | Required (diff-scoped) | Required |
| Estimated Time | < 2 hours | Any |
| Scope | Clear, bounded | Any |
| Commits | 1-2 | Per milestone |
