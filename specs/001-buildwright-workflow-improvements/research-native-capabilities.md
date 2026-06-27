# Research: Native Host-Tool Capabilities (mid-2026)

**Purpose**: Ground FR-005/FR-006 (US3 — prefer native host-tool capabilities) and
inform the fixes for US1 (plan-write reliability) and US2 (faithful handoff).
Buildwright targets **Claude Code, Codex, Cursor, and OpenCode** — all four are
surveyed below.

**Date**: 2026-06-27. Capabilities evolve fast; re-verify at implementation time.

## Headline finding

**Every supported host already ships a native "plan vs build" separation and
native primitives for command invocation, task tracking, subagents, and hooks.**
Buildwright's `/bw-plan` and `/bw-work` should map onto these native modes rather
than reimplement them in prose — which is also the likely root cause of the
US1 stuck-writer and the US2 memory-based handoff.

## Per-tool capability matrix

| Capability | Claude Code | Codex CLI | Cursor (CLI/IDE) | OpenCode |
|---|---|---|---|---|
| Plan vs build modes | Plan mode (Shift+Tab) + `EnterPlanMode`/`ExitPlanMode` tools | `/plan` command | Plan mode (`/plan` or `--mode=plan`), "Build in Cloud" handoff | Built-in **Plan** + **Build** primary agents (Plan is tool-restricted) |
| Faithful command/skill invocation | `Skill` tool re-injects the real skill content; custom `/commands` | Skills (custom prompt commands deprecated in favor of skills) | Commands + skills + plugins (managed via Customize page) | Custom commands (markdown, `$ARGUMENTS`); `@`-mention agents |
| Task / todo tracking | `TaskCreate`/`TaskList`/`TaskGet`/`TaskUpdate` (replaced `TodoWrite`); session-scoped | `/agent`, `/goal` | Task tool (drives subagents) | Task tool w/ `permission.task` glob control |
| Subagents / isolated context | `Agent` tool, foreground+background, own context, returns summary | `/agent`, `/fork`, `/side` parallelism | Subagents (since 2.5 can nest one level); async subagents | Subagents: General, Explore, Scout; invoked via Task tool |
| Hooks | `PreToolUse`, `PostToolUse`, `Stop`, `SessionStart`, compaction, subagent/task lifecycle | (config-driven; AGENTS.md first-turn load) | `sessionStart/End`, `pre/postToolUse`, `stop`, `beforeSubmitPrompt`, `subagentStart/Stop`, shell/MCP/file hooks | (agent/permission config) |
| Project instruction file | `CLAUDE.md` | `AGENTS.md` (first-turn, `project_doc_max_bytes`) | `AGENT.md` / rules | `AGENTS.md` |
| Context management | Auto-compaction, `/compact <focus>`, compact instructions, subagent isolation; **no native stash/restore** (only `--fork-session`) | — | Cloud handoff offloads execution | Plan/Build separation limits bloat |

## Design implications for this feature

- **US1 (plan-write reliability)**: Prefer the host's native plan-mode /
  structured-plan output and native file writing instead of a bespoke
  "announce then write" text sequence. On Claude Code that means
  `EnterPlanMode`/`ExitPlanMode`; the bespoke pattern is the suspected cause of
  the stuck/interrupt loop.
- **US2 (faithful handoff)**: Use the host's native command/skill invocation so
  the real `/bw-work` prompt executes (Claude Code `Skill` tool; Codex/OpenCode/
  Cursor command invocation). Where native invocation from inside a command is
  not guaranteed, **direct the user to run `/bw-work`** — never run it "from
  memory." This matches the team's Slack consensus.
- **US3 (native capabilities)**: Map `/bw-plan` → native Plan mode/agent and
  `/bw-work` → native Build mode/agent on each host; use native task tracking for
  sequences (US4) and native hooks where helpful. Provide a documented prose
  fallback per FR-006 for any host missing a capability.
- **US4 (auto-continue)**: Native task tracking (`Task*` tools / Plan→Build
  agents) is the substrate; a `Stop`/lifecycle hook can nudge continuation but
  runs in the harness, not in-context, so it cannot re-prompt directly —
  continuation logic should live in the command/agent flow, gated by
  `BUILDWRIGHT_AUTO_APPROVE`.
- **Follow-up research (context management)** is confirmed host-limited: none of
  the four expose a plugin-level stash/restore of conversation context. Claude
  Code offers auto-compaction + `--fork-session`; that's the closest lever.

## Caveats

- Some Claude Code specifics (exact hook-event names, tool version numbers) came
  from a docs-research subagent and should be re-confirmed against
  `code.claude.com/docs` before relying on them in implementation.
- Codex marks custom *prompt commands* deprecated in favor of *skills* — author
  Buildwright's Codex surface as skills.

## Sources

- Claude Code: [how-claude-code-works](https://code.claude.com/docs/en/how-claude-code-works.md),
  [tools-reference](https://code.claude.com/docs/en/tools-reference.md),
  [skills](https://code.claude.com/docs/en/skills.md),
  [sub-agents](https://code.claude.com/docs/en/sub-agents.md),
  [hooks](https://code.claude.com/docs/en/hooks.md)
- Codex: [slash commands](https://developers.openai.com/codex/cli/slash-commands),
  [AGENTS.md](https://developers.openai.com/codex/guides/agents-md),
  [features](https://developers.openai.com/codex/cli/features)
- Cursor: [subagents](https://cursor.com/docs/subagents),
  [hooks](https://cursor.com/docs/hooks),
  [CLI usage](https://cursor.com/docs/cli/using),
  [changelog 2.4](https://cursor.com/changelog/2-4) / [2.5](https://cursor.com/changelog/2-5),
  [CLI plan mode](https://cursor.com/changelog/cli-jan-16-2026)
- OpenCode: [agents](https://opencode.ai/docs/agents/),
  [commands](https://opencode.ai/docs/commands/)
