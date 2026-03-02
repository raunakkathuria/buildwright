# Approve Intent, Ship Autonomously: Buildwright

*What happens when you stop reviewing AI code and start approving intent*

---

Every team using AI coding tools hits the same wall.

The AI writes code fast. Genuinely fast. But then someone has to review it. Check for security issues. Make sure it actually fits the existing codebase. Run the tests. Read through the diff line by line.

You traded writing time for review time. **The human is still the bottleneck.** And the loop is still manual.

Your senior engineers — the ones you need designing systems and unblocking teams — are now spending their days reviewing AI-generated pull requests. That's not a productivity gain. That's a lateral move.

---

## The question that actually matters

"Can AI code?" stopped being interesting a while ago. The answer is yes. It can write functions, build components, wire up APIs. We're past that.

The better question: **Can AI ship?**

Can it research your codebase before touching it? Can it write a spec that considers multiple approaches? Can it review its own work for security vulnerabilities? Can it handle failures without leaving orphaned branches and mystery state?

That's a different bar entirely.

---

## The mental model

This is the idea behind [Buildwright](https://github.com/raunakkathuria/buildwright).

**Approve Intent** is the single human touchpoint — you read a one-page spec and say yes or no before a line of code is written. **Ship Autonomously** is everything after that — the agent runs the full loop without coming back to you: build, test, security scan, code review, PR.

One decision point. Everything else is automated.

---

## One spec. Then the agent disappears

A junior developer needs to add OAuth2 login.

**The old way**: Prompt the AI. Review 400 lines. Find an integration bug the AI missed. Re-prompt. Senior reviews for security. Someone runs tests. Three days, 6-8 touchpoints.

**The new way**: Run `/bw-new-feature "Add OAuth2 login"`. The agent reads the existing auth middleware, identifies services to reuse, and writes a one-page spec with two design approaches. The junior reads it. Says "approved."

Then the agent disappears.

It builds with TDD, runs typechecks and tests, does an OWASP scan, has a Staff Engineer persona review the code, and opens the PR. If anything fails, it commits the completed work, creates a structured failure report, and exits cleanly — no orphaned branches, no mystery state.

**One human touchpoint: the spec approval.**

---

## The job changes. Not just the speed.

Your senior engineers stop being review bottlenecks. The agent handles code review and security review through specialized personas. Your seniors go back to designing systems and mentoring — the work that actually requires a human brain.

Quality becomes a system property, not a person dependency. Every feature goes through the same gates: typecheck, lint, test, build, OWASP scan, Staff Engineer review. It doesn't matter if your best engineer is on vacation. The bar stays the same.

Junior developers ship with senior-level guardrails. A junior running `/bw-new-feature` gets the same research phase, spec validation, and review pipeline that a senior would follow. The workflow enforces the discipline — not the person watching over their shoulder.

You get audit trails you never had to write. Every feature produces a `research.md` and a `spec.md` — generated from the actual codebase, not someone's memory.

---

## Five commands. One loop.

[Buildwright](https://github.com/raunakkathuria/buildwright) is an open-source workflow you install into any project in about 60 seconds. Works with Claude Code, OpenCode, and OpenClaw via the Agent Skills format — giving agents the same structure a senior engineer follows, without you having to supervise it.

New feature with unclear scope? `/bw-new-feature` — the research phase prevents building the wrong thing. Bug fix or small task? `/bw-quick` — no ceremony, just fix, verify, commit. Ready to ship? `/bw-ship` — runs the full quality pipeline before creating a PR.

---

## How it compares to the other framework you've heard of

[GSD (Get Shit Done)](https://github.com/gsd-build/get-shit-done) solves a different problem. GSD fixes context rot — the quality degradation that happens as a Claude session fills up. It keeps context low, runs tasks in fresh windows, executes plans in parallel. Its tagline is accurate: *"Claude Code is powerful. GSD makes it reliable."*

Buildwright solves the review bottleneck — replacing manual diffs, security checks, and code review with automated quality gates, compressing all human involvement into a single spec approval. GSD is for solo devs moving fast. Buildwright is for teams where quality gates aren't optional. They're complementary — you could layer them, but that's overkill for most teams.

---

## Try it

**1. Install**

```bash
curl -sL https://raw.githubusercontent.com/raunakkathuria/buildwright/main/setup.sh | bash
```

About 60 seconds. Creates commands, agent personas, steering docs, quality gates, and CI workflow.

**2. Configure your steering docs**

```bash
nano .buildwright/steering/product.md  # product vision, key features
nano .buildwright/steering/tech.md     # tech stack, conventions
```

**3. Load the skills**

*Claude Code* — handled by the install script. Skills live in `.buildwright/commands/`.

*OpenCode* — handled by the install script. Skills live in `.opencode/commands/`. For global use across all projects:
```bash
mkdir -p ~/.config/opencode/skills/buildwright
cp .opencode/commands/* ~/.config/opencode/skills/buildwright/
```

*OpenClaw* — copy to your workspace or shared directory:
```bash
# Per-project (this workspace only)
mkdir -p skills/buildwright
cp .opencode/commands/* skills/buildwright/

# Or shared across all projects
mkdir -p ~/.openclaw/skills/buildwright
cp .opencode/commands/* ~/.openclaw/skills/buildwright/
```

**4. Run your first command**

*Claude Code:*
```bash
claude
> /bw-new-feature "Add user authentication with OAuth2"
```

*OpenCode:*
```bash
opencode
> /bw-new-feature "Add user authentication with OAuth2"
```

*OpenClaw:*
```bash
openclaw
"Add user authentication with OAuth2 with buildwright philosophy" 
```

Same commands, different runner. Say "approved" after the spec and it builds.

For something smaller — no spec, no ceremony:

```bash
> /bw-quick "Fix the login timeout bug"
```

Just fix, verify, commit.

---

*The goal isn't faster code. It's a shorter loop between intent and shipped.*

---

The repo is open source: **[github.com/raunakkathuria/buildwright](https://github.com/raunakkathuria/buildwright)**

What's working? What's still broken? Drop a comment or reach out.
