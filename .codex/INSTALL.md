# Installing Buildwright for Codex CLI

Enable Buildwright workflow skills in Codex via native skill discovery.

Codex gets Buildwright in two complementary ways:

- **Project instructions** — `AGENTS.md` at the repo root. Codex reads it
  natively when run inside the project; no install step is required. This is the
  single canonical instruction file shared by Claude Code, OpenCode, and Cursor.
- **Workflow skills** — the 5 `bw-*` skills, installed via the symlink below.

## Prerequisites

- Git
- make

## Installation

1. Clone Buildwright:

   ```bash
   git clone https://github.com/raunakkathuria/buildwright.git ~/.codex/buildwright
   cd ~/.codex/buildwright
   make sync
   ```

2. Create the skills symlink:

   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/buildwright/skills ~/.agents/skills/buildwright
   ```

   Or run this from the cloned directory:

   ```bash
   make codex
   ```

   To install Buildwright globally for every supported tool at once (Claude
   Code, Codex, OpenCode, OpenClaw), run `make global` instead.

3. Restart Codex to discover the skills.

## Verify

```bash
ls ~/.agents/skills/buildwright/
# Should show: bw-analyse/ bw-plan/ bw-ship/ bw-verify/ bw-work/
```

## Available Skills

| Skill | Purpose |
|-------|---------|
| `bw-analyse` | Analyse a brownfield codebase and write context docs |
| `bw-plan` | Research a question and produce a written deliverable |
| `bw-ship` | Verify, security review, code review, push, and PR |
| `bw-verify` | Run typecheck, lint, test, and build gates |
| `bw-work` | Implement bug fixes, refactors, and features |

## Updating

```bash
cd ~/.codex/buildwright
git pull
make sync
```

Skills update through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/buildwright
# Optionally: rm -rf ~/.codex/buildwright
```
