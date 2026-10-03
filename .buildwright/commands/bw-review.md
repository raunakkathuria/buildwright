---
name: bw-review
description: Independently review a PR or local changes for code and security issues without modifying code. Use before shipping or when a standalone review is requested.
metadata:
  author: raunakkathuria
  version: "0.0.21"
---

# /bw-review — independent code + security review

Run a **review-only** pass — code **and** security — over a set of changes, without implementing or
shipping anything. Use it to review an existing PR (yours, a teammate's, or another agent's) or your
working changes before `/bw-ship`. It is the single home for the review logic that `/bw-work` and
`/bw-ship` delegate to (DRY).

**Independent by construction:** the reviewer must not be the implementer. Run each persona pass in
a **sub-agent** (see `framework/capability.md`). This way it starts with only the diff, the persona
and the stated requirement (the PR title and body, or the task or spec the caller names). Not the
session that wrote the code, and not the author's account of why. The two
passes do not depend on each other, so run them **in parallel** where the host supports it.

Where the host has no sub-agents, fall back to adopting the persona inline. This is weaker, so name
it. An author who reviews their own change already knows what was deliberate and what was "out of
scope". So they find fewer things. **Say which of the two happened** in
the report, so a reader knows how much the verdict is worth.

Review only what changed; verify each issue is real and introduced by these changes.

**Judgment-class, report-only.** It never edits code and never merges. Findings are advice for a
human: a blocking finding is cleared by a fix or by an override (see Phase 4). A "before-production"
concession is recorded in `.buildwright/framework/findings.md`. It is not a deterministic gate.

## Invocation

```
/bw-review                      # review the local changes: branch commits and uncommitted work
/bw-review <pr-number|pr-url>    # review a GitHub PR by its diff
/bw-review --comment            # (with a PR) post findings as PR review comments instead of only printing
```

## Phase 1: Resolve the target (what to review)

- **A PR** (number/URL given): fetch its diff and metadata —
  ```bash
  gh pr diff <pr>                       # the unified diff
  gh pr view <pr> --json title,body,files
  ```
  Optionally check it out (`gh pr checkout <pr>`) if running tools that need the tree.
- **Local changes** (no argument): everything since the branch left the default branch —
  commits **and** uncommitted work, because `/bw-work` and `/bw-ship` review before they commit —
  plus new untracked files:
  ```bash
  base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo main)
  mb=$(git merge-base "$base" HEAD 2>/dev/null) || mb=HEAD  # no base: uncommitted work only
  git diff "$mb"                            # commits + staged + unstaged changes
  git ls-files --others --exclude-standard  # new files git diff does not show
  ```

Review **only** the changed lines and their blast radius — never the whole repo.

## Phase 2: Security review (Security Engineer persona)

Run this pass in a sub-agent, given the diff and `.buildwright/agents/security-engineer.md` (or
`~/.claude/agents/security-engineer.md` for a global install without a project `.buildwright/`).
Inline fallback per the header.

- **Automated scans** (skip gracefully if a tool is absent), on the changed files only: secrets
  (API keys, tokens, private keys); SAST (`semgrep --config p/owasp-top-ten <changed files>`).
  Run a dependency audit (`npm audit` / `cargo audit` / `pip-audit` …) only when the diff changes a
  manifest or lock file, and report only advisories for packages the diff adds or changes.
- **Manual, phased:** repository context → comparative analysis (does the change follow or weaken
  existing controls?) → OWASP Top 10 (A01–A10) over the changed code. Watch financial-code risks
  (floating point for money).
- **Critical vulnerability → stop and report** (no auto-fix; needs human judgment).

## Phase 3: Code review (Staff Engineer persona)

Run this pass in a sub-agent, given the diff and `.buildwright/agents/staff-engineer.md` (or the
global path as above). Inline fallback per the header.

- **Phased:** repository context → comparative analysis (pattern fit; reuse over reinvention;
  DRY/YAGNI) → issue assessment. For each candidate issue, verify it is real and **introduced** by
  these changes; assign confidence and **report only ≥ 80**.
- Cover the persona's "In Code" checklist: logic errors, edge cases, error handling, complexity,
  missing validation, and missing tests/docs. Per `framework/tdd-evidence.md`, also flag **new/changed
  tests with no cited red**, unless they are declared characterization guards.

## Phase 4: Report

Emit one consolidated result — security then code — each with a verdict and findings
(severity · file:line · why it matters · suggested fix · confidence). With `--comment` on a PR, post
them as review comments; otherwise print them. State clearly:

- **PASS** — no blocking findings; safe to proceed / merge (a human still merges).
- **BLOCKED** — blocking security or code findings; route back to the implementer, who fixes each
  one or overrides it.

**Blocking** means a security finding rated **Critical** or **High**, or a code finding under
**Critical Issues**. Everything else (security Medium and Low, code Recommendations and
Observations) is reported but does not block. `/bw-work` and `/bw-ship` use this definition.

**Override:** the developer may skip a blocking finding by adding one line to the PR body, or to a
commit message on the branch when there is no PR: `Override: <finding title> — <reason>`. Only the
developer writes this line, never the agent. On the next run, Phase 4 reads these lines
(`gh pr view <pr> --json body`, or `git log --format=%B "$mb"..HEAD`). It lists each overridden
finding with its reason and does not count it as blocking. A finding with no override line still
blocks.

Never modify code and never merge — this command only reviews.
