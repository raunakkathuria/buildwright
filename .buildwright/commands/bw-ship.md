---
name: bw-ship
version: 0.0.17
description: Run full quality pipeline (verify → security → review) then commit, push, and create PR. Fails fast if any step fails.
arguments:
  - name: message
    description: Commit message (conventional format). Required if there are uncommitted changes.
    required: false
---

## Ship Pipeline

This command runs the full quality pipeline before shipping.

Failure handling follows the single autonomy behaviour in
`.buildwright/framework/autonomy.md` (context-inferred — no mode flag). Any
"acceptable for staging, fix before production" decision surfaced during review
is recorded per `.buildwright/framework/findings.md` (before-production class) so
it is not lost at release time.

```
┌─────────────────────────────────────────────────────────────┐
│                      SHIP PIPELINE                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. VERIFY (quick checks) ← fix & re-run                    │
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

## Gate reuse (avoid redundant re-runs)

Steps 1–3 (Verify, Security, Review) are the same gates `/bw-work` and
`/bw-verify` already run. When `/bw-ship` is chained after them in the same run,
re-running on unchanged code is pure waste. Before each gate, check the current
state:

```bash
git rev-parse HEAD
git status --porcelain
```

If this exact gate already passed **earlier in this run** at the same `HEAD` with
an identical working tree — e.g. `/bw-work` Phases 6–8 or `/bw-verify` just ran
it — **skip it and carry the prior result forward**, marking that step's box
`↺ REUSED (passed at <sha>)`. Run the gate normally when:

- the working tree changed since it last passed (`git status --porcelain` differs),
- you cannot confirm a prior pass in this run (e.g. `/bw-ship` invoked standalone
  after manual edits, or in a fresh session), or
- the gate previously failed.

When in doubt, run it — reuse is an optimization, never a reason to ship
unverified code.

---

## Step 1: Verify (Quick Checks) — fix and re-run until passing

Apply **Gate reuse** above before running.

Before verifying, confirm documentation reflects the changes being shipped.
Update affected README, docs, command text, API docs, examples, or CHANGELOG.
If no docs need updating, record why in the final report. Documentation is part
of done.

Run quick verification checks:

```bash
# Discover and run project commands
# Type check
# Lint
# Test
# Build
```

**If fails → Fix and re-run. Keep going while you are making progress.**
**If the same error repeats, or there is no diagnosable fix → Not making progress — handle failure (see below).**
**Do not loop indefinitely. When a gate stalls → Handle failure:**

Handle failure per the **Failure Handling** section below (context-inferred).

```
╔═══════════════════════════════════════════════════════════════╗
║  STEP 1: VERIFY                                               ║
╠═══════════════════════════════════════════════════════════════╣
║  Type Check:  ✅/❌                                            ║
║  Lint:        ✅/❌                                            ║
║  Tests:       ✅/❌                                            ║
║  Build:       ✅/❌                                            ║
╠═══════════════════════════════════════════════════════════════╣
║  Status: PASS / RETRY / FAIL                                  ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## Step 2: Security Review — No retry (needs human judgment)

Adopt the Security Engineer persona from `.buildwright/agents/security-engineer.md`.
For a global install in a project without `.buildwright/`, read it from
`~/.claude/agents/security-engineer.md` instead.

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
[DISCOVERED_AUDIT_COMMAND] 2>/dev/null || echo "Dependency audit not available for this stack"
semgrep --config p/owasp-top-ten . 2>/dev/null || echo "semgrep not available"
```

Where DISCOVERED_AUDIT_COMMAND is the stack-appropriate audit tool, e.g.:
`npm audit` | `cargo audit` | `pip-audit` | `bundle audit` | `go list -m -json all | nancy sleuth`

### 2.3 Manual Review (Phased)

**Phase A — Repository Context:** Understand existing security posture — frameworks, middleware, auth patterns, trust boundaries.

**Phase B — Comparative Analysis:** Does new code follow established security patterns? Does it bypass or weaken existing controls?

**Phase C — Vulnerability Assessment:** Check changed code against OWASP Top 10 (A01-A10) using the full checklist from the Security Engineer persona.

**If CRITICAL vulnerabilities found → No retry.** Security issues need human
judgment. Handle failure per the **Failure Handling** section below
(context-inferred).

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

---

## Step 3: Code Review — No retry (architectural decisions)

Adopt the Staff Engineer persona from `.buildwright/agents/staff-engineer.md`.
For a global install in a project without `.buildwright/`, read it from
`~/.claude/agents/staff-engineer.md` instead.

### 3.1 Determine Scope
```bash
git diff main...HEAD
# Or if no main branch:
git diff HEAD
```

### 3.2 Phased Review

**Phase A — Repository Context:** Understand existing patterns, conventions, error handling, and testing approaches.

**Phase B — Comparative Analysis:** Does new code follow established patterns? Does it reuse existing utilities and types instead of reimplementing? Does it bypass or weaken existing controls?

**Phase C — Issue Assessment:** Review changes for real issues. For each: verify it's real, confirm it was INTRODUCED by these changes, assign confidence (only report ≥ 80).

Assess against categories from the Staff Engineer persona's "In Code" checklist.

**⚠️ APPROVED WITH COMMENTS** → Proceed to release. Fix recommendations if straightforward, otherwise note for follow-up.
**❌ CHANGES REQUESTED** → No retry. Code review issues often involve
architectural decisions that need human input. Handle failure per the **Failure
Handling** section below (context-inferred).

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

### 4.3 Check for a remote

Push and PR both require a configured remote. Check first:

```bash
git remote
```

**If no remote is configured** (empty output), you cannot push or open a PR.
This is not a failure — the work is committed and verified locally. Stop here
and report the **No-remote outcome** (see below): the work is preserved on the
feature branch as a local commit, and the human can add a remote and push when
ready. Do **not** treat this as a `[FAILED]` ship.

### 4.4 Push
```bash
# Push to remote (only if a remote exists)
git push origin HEAD
```

### 4.5 Create PR
```bash
# Create pull request
gh pr create --fill
```

If `gh` is not available, provide the PR creation URL.

### No-remote outcome

```
╔═══════════════════════════════════════════════════════════════╗
║                  SHIPPED LOCALLY (no remote)                  ║
╠═══════════════════════════════════════════════════════════════╣
║  ✅ Verify / Security / Review:  PASSED                       ║
║  ✅ Commit:   [commit hash]                                   ║
║  ⏭ Push/PR:  SKIPPED — no git remote configured              ║
╠═══════════════════════════════════════════════════════════════╣
║  Next: add a remote (`git remote add origin <url>`),          ║
║  then `git push -u origin HEAD` and open a PR.                ║
╚═══════════════════════════════════════════════════════════════╝
```

Exit zero — quality passed and the commit is safe on the branch.

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
║  ✅ Docs:      UPDATED / NOT APPLICABLE                       ║
║  ✅ Release:   SHIPPED                                        ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║  Commit:  [commit hash]                                       ║
║  Branch:  [branch name]                                       ║
║  PR:      [PR URL]                                            ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Quality gates will run in CI.                                ║
║  PR ready for team review when all gates pass.                ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

## Failure Handling

Infer the execution context per `.buildwright/framework/autonomy.md` — there is
no mode flag, and that doc is the single source for how interactivity is
detected and how each context behaves. The boxes and the failure-summary
template below are the `/bw-ship`-specific presentation of that behaviour.

### Interactive (a TTY is attached, no CI signal)

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

### Unattended (`CI` / `GITHUB_ACTIONS` set, or no TTY)

Preserve completed work, surface the failure, and exit non-zero:

1. Stage and commit all completed work to the feature branch.
2. Check for a remote (`git remote`):
   - **Remote exists**: push the branch, then open a PR whose title is prefixed
     `[FAILED]` and whose body uses the failure summary template below.
   - **No remote**: skip push and PR — they are impossible. Print the failure
     summary (filled from the template) to the run output so the failure is
     still visible in logs. The completed work remains as a local commit.
3. Exit with a non-zero code so CI/CD registers the failure.

### Failure summary template

Use this for the `[FAILED]` PR body (or the printed summary when no remote exists):

```markdown
## BUILDWRIGHT: Pipeline Failed

**Feature:** [name]
**Failed at:** [Verify / Security / Review]
**Reason:** [Progress stalled / Critical vulnerability / Changes requested]

### Pipeline Status
| Step | Status | Details |
|------|--------|---------|
| Verify | [pass/fail] | [details] |
| Security | [pass/fail/skipped] | [details] |
| Review | [pass/fail/skipped] | [details] |

### Completed Work
- [completed milestones/steps]

### Failure Details
- [error summary, specific findings, or review feedback]

### Skipped
- [steps blocked by the failure]

### To Resume
Fix the issue on this branch, then re-run the relevant command.
```

---

## Multi-Agent Safety

- Only commit files you modified
- Never use `git stash`
- Pull before push if needed
- Use atomic commits
