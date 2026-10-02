# Agent Personas

This folder holds the review personas. Each file is a valid agent
definition (with `name`/`description` frontmatter). So tools that expect a
subagent registry load them cleanly: Claude Code (`.claude/agents/`,
`~/.claude/agents/`) and OpenCode (`.opencode/agents/`). But `/bw-review` still
adopts them **inline**. It does not spawn them as separate runtimes, because
Buildwright is not a multi-agent framework.

| Agent | File | Adopted By | Purpose |
|-------|------|------------|---------|
| Staff Engineer | `staff-engineer.md` | `/bw-review` (called by `/bw-work`, `/bw-ship`) | Spec and code review with confidence scoring and high-signal findings |
| Security Engineer | `security-engineer.md` | `/bw-review` (called by `/bw-work`, `/bw-ship`) | OWASP Top 10, secrets, auth, injection, dependency review |

## How they are triggered

The review logic lives in one place: `/bw-review`, which adopts both personas.
`/bw-work` and `/bw-ship` call it and do not repeat the review. Only where a host
cannot run `/bw-review` faithfully do they adopt the personas inline:

- `/bw-work` — Phase 7 (Review) runs `/bw-review` once the code passes its
  verification gates, before commit.
- `/bw-ship` — Step 2 (Review) runs `/bw-review` as part of the ship pipeline,
  before push/PR.

`/bw-review` adopts the matching persona — reading it from the project's
`.buildwright/agents/<name>.md`, or from `~/.claude/agents/<name>.md` for a
global install without a project `.buildwright/`.
