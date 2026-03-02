---
name: bw-ship
description: Run full quality pipeline (verify → security → review) then commit, push, and create PR. Fails fast if any step fails.
arguments:
  - name: message
    description: Commit message (conventional format). Required if there are uncommitted changes.
    required: false
---

## Ship Pipeline

This command runs the full quality pipeline before shipping.

```
┌─────────────────────────────────────────────────────────────┐
│                      SHIP PIPELINE                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. VERIFY (quick checks) ← Retry up to 2x                  │
│     └─ typecheck → lint → test → build                     │
│              │                                              │
│              ▼ PASS? Continue : Retry/STOP                  │
│                                                             │
│  2. SECURITY (OWASP + SAST) ← No retry                      │
│     └─ dependencies → secrets → OWASP scan                 │
│              │                                              │
│              ▼ PASS? Continue : STOP                        │
│                                                             │
│  3. REVIEW (Staff Engineer) ← No retry                      │
│     └─ logic → errors → patterns → quality                 │
│              │                                              │
│              ▼ PASS? Continue : STOP                        │
│                                                             │
│  4. RELEASE                                                 │
│     └─ commit → push → create PR                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 1: Verify (Quick Checks) — Retry up to 2x

Run quick verification checks:

```bash
# Discover and run project commands
# Type check
# Lint
# Test
# Build
```

**If fails → Fix and retry (up to BUILDWRIGHT_AGENT_RETRIES attempts, default 2).**
**If same error repeats → Not making progress — handle failure (see below).**
**If still failing after retries → Handle failure:**

- **Autonomous** (`BUILDWRIGHT_AUTO_APPROVE=true`, default): Commit completed work, push branch, create PR with failure summary (see BUILDWRIGHT.md template), exit(1).
- **Interactive** (`BUILDWRIGHT_AUTO_APPROVE=false`): STOP and report blocker to human.

```
╔═══════════════════════════════════════════════════════════════╗
║  STEP 1: VERIFY                                               ║
╠═══════════════════════════════════════════════════════════════╣
║  Type Check:  ✅/❌                                            ║
║  Lint:        ✅/❌                                            ║
║  Tests:       ✅/❌                                            ║
║  Build:       ✅/❌                                            ║
╠═══════════════════════════════════════════════════════════════╣
║  Attempt: [1/2/3]                                             ║
║  Status: PASS / RETRY / FAIL                                  ║
╚═══════════════════════════════════════════════════════════════╝
```

If FAIL after retries:
- **Autonomous**: Commit + push + create failed PR (using BUILDWRIGHT.md template) + exit(1).
- **Interactive**: Report specific errors and STOP.

---

## Step 2: Security Review — No retry (needs human judgment)

Adopt Security Engineer persona from `.buildwright/agents/security-engineer.md`.

### 2.1 Determine Scope
```bash
git diff --name-only main...HEAD
# Or if no main branch:
git diff --name-only HEAD
```

### 2.2 Automated Scans
Run tools from the Security Engineer persona's "Tools to Use" section:
- Dependency vulnerabilities (`npm audit` / `cargo audit` / etc.) — skip gracefully if unavailable
- Secrets detection (pattern scan for API keys, passwords, tokens, private keys)
- SAST (`semgrep --config p/owasp-top-ten .` if available)

```bash
# Skip gracefully if tools are unavailable
npm audit 2>/dev/null || echo "npm audit not available"
semgrep --config p/owasp-top-ten . 2>/dev/null || echo "semgrep not available"
```

### 2.3 Manual Review (Phased)

**Phase A — Repository Context:** Understand existing security posture — frameworks, middleware, auth patterns, trust boundaries.

**Phase B — Comparative Analysis:** Does new code follow established security patterns? Does it bypass or weaken existing controls?

**Phase C — Vulnerability Assessment:** Check changed code against OWASP Top 10 (A01-A10) using the full checklist from the Security Engineer persona.

**If CRITICAL vulnerabilities found → No retry. Handle failure:**

- **Autonomous** (`BUILDWRIGHT_AUTO_APPROVE=true`, default): Commit completed work, push branch, create PR with failure summary (see BUILDWRIGHT.md template), exit(1).
- **Interactive** (`BUILDWRIGHT_AUTO_APPROVE=false`): STOP immediately. Security issues require human judgment.

```
╔═══════════════════════════════════════════════════════════════╗
║  STEP 2: SECURITY                                             ║
╠═══════════════════════════════════════════════════════════════╣
║  Dependencies:  ✅/❌  ([N] vulnerabilities)                   ║
║  Secrets:       ✅/❌  ([N] found)                             ║
║  OWASP Scan:    ✅/❌  ([N] issues)                            ║
╠═══════════════════════════════════════════════════════════════╣
║  Status: SECURE / CRITICAL VULNERABILITIES                    ║
╚═══════════════════════════════════════════════════════════════╝
```

If CRITICAL VULNERABILITIES:
- **Autonomous**: Commit + push + create failed PR (using BUILDWRIGHT.md template) + exit(1).
- **Interactive**: Report specific issues and STOP.

---

## Step 3: Code Review — No retry (architectural decisions)

Adopt Staff Engineer persona from `.buildwright/agents/staff-engineer.md`.

### 3.1 Determine Scope
```bash
git diff main...HEAD
# Or if no main branch:
git diff HEAD
```

### 3.2 Phased Review

**Phase A — Repository Context:** Understand existing patterns, conventions, error handling, and testing approaches.

**Phase B — Comparative Analysis:** Does new code follow established patterns? Does it bypass or weaken existing controls?

**Phase C — Issue Assessment:** Review changes for real issues. For each: verify it's real, confirm it was INTRODUCED by these changes, assign confidence (only report ≥ 80).

Assess against categories from the Staff Engineer persona's "In Code" checklist.

**⚠️ APPROVED WITH COMMENTS** → Proceed to release. Fix recommendations if straightforward, otherwise note for follow-up.
**❌ CHANGES REQUESTED** → No retry. Handle failure:

- **Autonomous** (`BUILDWRIGHT_AUTO_APPROVE=true`, default): Commit completed work, push branch, create PR with failure summary (see BUILDWRIGHT.md template), exit(1).
- **Interactive** (`BUILDWRIGHT_AUTO_APPROVE=false`): STOP immediately. Code review issues often involve architectural decisions that need human input.

```
╔═══════════════════════════════════════════════════════════════╗
║  STEP 3: CODE REVIEW                                          ║
╠═══════════════════════════════════════════════════════════════╣
║  Logic:         ✅/❌                                          ║
║  Error Handling:✅/❌                                          ║
║  Performance:   ✅/❌                                          ║
║  Maintainability:✅/❌                                         ║
╠═══════════════════════════════════════════════════════════════╣
║  Status: APPROVED / CHANGES REQUESTED                         ║
╚═══════════════════════════════════════════════════════════════╝
```

If CHANGES REQUESTED:
- **Autonomous**: Commit + push + create failed PR (using BUILDWRIGHT.md template) + exit(1).
- **Interactive**: Report specific issues and STOP.

---

## Step 4: Release

All checks passed. Now ship:

### 4.1 Stage Changes
```bash
git add [specific files you changed]  # NEVER git add -A
```

### 4.2 Commit
```bash
# Use provided message or generate from changes
git commit -m "$ARGUMENTS.message"
```

If no message provided and there are changes, generate a conventional commit message based on the changes.

### 4.3 Push
```bash
# Push to remote
git push origin HEAD
```

### 4.4 Create PR
```bash
# Create pull request
gh pr create --fill
```

If `gh` is not available, provide the PR creation URL.

---

## Final Report

```
╔═══════════════════════════════════════════════════════════════╗
║                        SHIP COMPLETE                          ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  ✅ Verify:    PASSED                                         ║
║  ✅ Security:  PASSED                                         ║
║  ✅ Review:    APPROVED                                       ║
║  ✅ Release:   SHIPPED                                        ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║  Commit:  [commit hash]                                       ║
║  Branch:  [branch name]                                       ║
║  PR:      [PR URL]                                            ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Quality gates will run in CI.                                ║
║  PR will auto-merge when all gates pass.                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## Failure Handling

### Interactive Mode (`BUILDWRIGHT_AUTO_APPROVE=false`)

STOP and show the blocker:

```
╔═══════════════════════════════════════════════════════════════╗
║                      SHIP BLOCKED                             ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  ❌ Failed at: [STEP NAME]                                    ║
║                                                               ║
║  Reason:                                                      ║
║  [Specific failure details]                                   ║
║                                                               ║
║  To fix:                                                      ║
║  [Actionable remediation steps]                               ║
║                                                               ║
║  After fixing, run /bw-ship again.                               ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

### Autonomous Mode (`BUILDWRIGHT_AUTO_APPROVE=true`, default)

Commit completed work, push, create PR with failure details, and exit(1):

1. Stage and commit all completed work to the feature branch
2. Push branch to remote
3. Create PR using the failure summary template from BUILDWRIGHT.md
4. Exit with non-zero code so CI/CD registers the failure

The PR title should be prefixed with `[FAILED]` and the body should follow the PR Failure Summary Template documented in BUILDWRIGHT.md.

---

## Multi-Agent Safety

- Only commit files you modified
- Never use `git stash`
- Pull before push if needed
- Use atomic commits
