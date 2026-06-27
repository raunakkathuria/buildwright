# Capabilities

Buildwright runs on several host agent tools (Claude Code, Codex, OpenCode,
Cursor). Where a host provides a capability natively, **prefer the native
capability** — do not reimplement it in command prose. Where a host lacks one,
fall back to the documented behaviour in the last column; **never fail** because
a capability is missing.

Commands reference these capabilities **generically** (e.g. "write the file with
the host's native file-write tool", "track the queue with native task
tracking"). This table is the single place that maps a capability to each host,
so the command text stays tool-agnostic.

| Capability | Claude Code | Codex | Cursor | OpenCode | Fallback when absent |
|------------|-------------|-------|--------|----------|----------------------|
| **Plan / build modes** | Plan mode (`EnterPlanMode`/`ExitPlanMode`) | `/plan` | Plan mode (`/plan`, `--mode=plan`) | built-in Plan / Build agents | proceed without a mode switch |
| **File write** | native file-write tool | native file-write | native file-write | native file-write | write the file directly, report errors |
| **Command invocation** (faithful) | `Skill` / slash-command invocation re-injects the real command | skill invocation | command/skill invocation | custom-command invocation | direct the user to run the command |
| **Task / todo tracking** | `TaskCreate`/`TaskList`/`TaskUpdate` | `/agent`, `/goal` | Task tool | Task tool | an in-prose checklist in the deliverable |
| **Sub-agents** | `Agent` tool (isolated context) | `/agent`, `/fork`, `/side` | subagents | General/Explore/Scout subagents | run the phase inline in the main flow |
| **Hooks** | lifecycle hooks (PreToolUse, Stop, …) | config-driven | session/tool hooks | agent/permission config | an explicit step in the command |

## Rules

1. **Prefer native.** If the host has the capability and it fits, use it.
2. **Always have a fallback.** Every capability above defines one; a host
   missing a capability degrades to it rather than erroring.
3. **Keep commands tool-agnostic.** Never hard-code one host's mechanism in a
   command file — name the capability and let this doc resolve it.

## Why this matters

Hand-rolled equivalents of native behaviour are where Buildwright's bugs have
lived — e.g. narrating "writing the plan now…" instead of issuing the host's
file-write (the `/bw-plan` stall), and continuing into implementation "from
memory" instead of invoking the real `/bw-work`. Leaning on native capabilities
removes that class of bug and keeps Buildwright aligned with each tool as it
evolves.
