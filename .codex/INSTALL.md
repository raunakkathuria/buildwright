# Installing Buildwright for Codex CLI

Enable Buildwright workflow skills in Codex via native skill discovery.

## Prerequisites

- Git
- make

## Installation

1. **Clone Buildwright** (or use your existing project copy):
   ```bash
   git clone https://github.com/raunakkathuria/buildwright.git ~/.codex/buildwright
   cd ~/.codex/buildwright && make sync
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/buildwright/skills ~/.agents/skills/buildwright
   ```

   **Or use `make codex`** to do steps 1-2 in one command (from the cloned directory):
   ```bash
   make codex
   ```

3. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

## Verify

```bash
ls ~/.agents/skills/buildwright/
# Should show: bw-analyse/ bw-claw/ bw-new-feature/ bw-plan/ bw-quick/ bw-ship/ bw-verify/
```

## Available Skills

Once installed, Codex will discover these Buildwright workflow skills:

| Skill | Purpose |
|-------|---------|
| `bw-analyse` | Analyse codebase: writes stack, architecture, conventions, concerns |
| `bw-claw` | Multi-agent: architect decomposes → claws execute per domain |
| `bw-new-feature` | Full pipeline: research → spec → approve → build → ship |
| `bw-plan` | Research a question, produce a written deliverable — no implementation |
| `bw-quick` | Fast path for bug fixes, small tasks, config changes |
| `bw-ship` | Quality gates + release: verify → security → review → push → PR |
| `bw-verify` | Quick checks: typecheck, lint, test, build |

## Updating

```bash
cd ~/.codex/buildwright && git pull && make sync
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/buildwright
# Optionally: rm -rf ~/.codex/buildwright
```
