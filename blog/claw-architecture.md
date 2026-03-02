# The Claw Architecture: Multi-Agent AI Development

One lobster. Multiple claws. Each claw grabs its domain.

## The Problem with AI-Assisted Development

You've probably experienced this:

```
You: "Add user authentication to my app"

AI: *generates a 500-line auth.js file*

You: *pastes it in*

App: *breaks in 47 different ways*
```

The AI wrote code in isolation. It didn't know about your existing patterns, your database schema, your API conventions, or your frontend state management.

Modern applications have multiple layers — UI, API, database, gateway, business logic. Each layer has its own conventions, its own patterns, its own expertise required.

A single AI trying to handle everything is like a surgeon trying to perform every role in an operating room. You need a team.

## Enter the Claw Architecture

```
                         🧠
                    ┌─────────┐
                    │ARCHITECT│
                    │ (Brain) │
                    └────┬────┘
                         │
           ┌─────────────┼─────────────┐
           │             │             │
           ▼             ▼             ▼
        ┌─────┐      ┌─────┐      ┌─────┐
        │ 🎨  │      │ ⚙️  │      │ 🗄️  │
        │ UI  │      │ API │      │ DB  │
        │Claw │      │Claw │      │Claw │
        └─────┘      └─────┘      └─────┘
```

The concept is inspired by OpenClaw's branding — a lobster that grabs and executes tasks, not just chats about them.

One lobster (an OpenClaw, Claude Code, or OpenCode instance) with multiple specialized claws (agents).

Each claw is an expert at grabbing work in its domain:

- **UI Claw** (`.buildwright/claws/frontend.md`): Knows React patterns, component libraries, accessibility, state management
- **API Claw** (`.buildwright/claws/backend.md`): Knows REST conventions, OpenAPI specs, authentication, error handling
- **DB Claw** (`.buildwright/claws/database.md`): Knows schema design, migrations, indexing, query optimization

The Brain — the Architect (`.buildwright/agents/architect.md`) — coordinates everything: analyzing requirements, creating plans, spawning claws, and combining results.

## The Anatomy

| Lobster Part | Architecture Role |
|---|---|
| Brain | Architect Agent — analyzes, plans, coordinates |
| Claws | Specialized Agents — grab and execute domain-specific work |
| Nervous System | Naming Conventions Registry — shared vocabulary across claws |
| Shell | Buildwright Quality Gates — verify, security, review |

## How It Works

### Step 1: You Request a Feature

```
/bw-claw "Add profile photo upload for team members"
```

### Step 2: Brain Analyzes

The Architect reads your codebase and `.buildwright/steering/` docs, then determines which claws need to grab work:

```
ARCHITECT: This feature touches:
- Database (store photo URL)
- API (upload endpoint)
- UI (upload component)

Registering fields in naming-conventions.md...
Creating claw plan...
```

### Step 3: Brain Registers the Contract

Before spawning claws, the Architect writes to `.buildwright/steering/naming-conventions.md`:

```
| Concept | Database | API (JSON) | UI (JS) |
|---------|----------|------------|---------|
| photo_url | photo_url | photoUrl | photoUrl |
```

And defines interface contracts in the claw plan — what each claw must produce and what it can assume about the others.

### Step 4: Brain Spawns Claws

Each claw gets spawned with its specific task:

```
🗄️ DB CLAW: "Add photo_url column to members table"
⚙️ API CLAW: "Add POST /api/members/:id/photo endpoint"
🎨 UI CLAW: "Add PhotoUpload component to MemberCard"
```

### Step 5: Claws Grab and Execute

Each claw:
1. Reads its domain-specific files (schema, routes, or components)
2. Looks up naming from the conventions registry — never invents its own
3. Implements with TDD
4. Runs `/bw-verify` against its work
5. Reports back to the Brain

```
🗄️ DB CLAW: ✅ Migration created, photo_url column added
⚙️ API CLAW: ✅ Upload endpoint ready, validates jpg/png, 2MB max
🎨 UI CLAW: ✅ PhotoUpload component added, drag-and-drop works
```

### Step 6: Brain Combines and Ships

```
ARCHITECT: All claws complete.
- Running integration test... ✅
- Security scan... ✅
- Staff Engineer review... ✅
- Creating PR...

PR ready: feature/add-profile-photo
```

## Why Claws, Not One Big Agent?

### 1. Context Window Efficiency

A single agent loading your entire codebase hits context limits fast.

Each claw loads only its domain:
- UI Claw: `ui/src/` (~500 lines)
- API Claw: `api/src/` (~300 lines)
- DB Claw: `database/` (~50 lines)

### 2. Deep Expertise

A generalist knows a bit about everything. A specialist is an expert.

The DB Claw knows: safe migration patterns, when to add indexes, how to handle rollbacks, SQLite-specific gotchas.

The UI Claw knows: your component library, accessibility requirements, state management patterns, performance optimization.

### 3. Parallel Work

```
Single Agent (Sequential):
  Research UI (2 min) → Research API (2 min) → Research DB (2 min)
  Total: 6 minutes

Multiple Claws (Parallel):
  UI Claw researches ─┐
  API Claw researches ├─► All done in 2 minutes
  DB Claw researches ─┘
```

### 4. Isolated Failures

If the UI Claw hallucinates bad code, it doesn't pollute the API Claw's context. Each claw starts fresh.

### 5. Different Models Per Domain

```
architect: "claude-opus-4"     // Complex planning needs best model
database: "claude-haiku-4"     // Simple migrations = cheap model
ui: "claude-sonnet-4"          // Balanced for code generation
```

## The Shell: Buildwright Quality Gates

The shell protects the lobster. Buildwright protects your code.

Every claw uses Buildwright for quality:

```
┌─────────────────────────────────────────────────────────────┐
│  BUILDWRIGHT SHELL                                          │
├─────────────────────────────────────────────────────────────┤
│  /bw-verify    → Typecheck, lint, test, build               │
│  /bw-ship      → Full pipeline: verify → security → review  │
│  /bw-claw      → Multi-agent: decompose → execute → ship    │
└─────────────────────────────────────────────────────────────┘
```

Each claw verifies its work. The brain does integration verification at the end.

## Shared Vocabulary: Naming Conventions

Claws need to speak the same language. When the DB Claw adds `photo_url`, the API Claw must know it's `photoUrl`, and the UI Claw must use `photoUrl`.

The naming conventions registry (`.buildwright/steering/naming-conventions.md`) keeps everyone aligned:

```
| Layer     | Convention   | Example                |
|-----------|-------------|------------------------|
| Database  | snake_case  | photo_url, created_at  |
| API JSON  | camelCase   | photoUrl, createdAt    |
| UI (JS)   | camelCase   | photoUrl, createdAt    |
| CSS       | kebab-case  | photo-upload           |
| URLs      | kebab-case  | /api/team-members/:id  |
```

Rules: The Architect registers fields before spawning claws. Claws derive their naming from the registry — they never invent their own. One source of truth.

## Building Your Own Claws

Buildwright ships with three claws (frontend, backend, database) and a `TEMPLATE.md` for building your own:

```bash
# Copy the template
cp .buildwright/claws/TEMPLATE.md .buildwright/claws/gateway.md

# Edit to match your domain
nano .buildwright/claws/gateway.md
```

A claw file defines: what the claw owns, its domain context, naming conventions for that layer, verification requirements, and what it must read before implementing.

## When to Use Claw Architecture

| Scenario | Approach |
|---|---|
| Single-domain feature | `/bw-new-feature` — one agent handles it |
| Bug fix, small task | `/bw-quick` — fast path, no decomposition |
| Feature touching 2+ domains | `/bw-claw` — architect decomposes, claws execute |
| Greenfield project | `/bw-new-feature` first (sets up steering), then `/bw-claw` for cross-cutting features |

Start simple. `/bw-new-feature` auto-detects when a feature crosses domain boundaries and suggests escalating to `/bw-claw`.

## Setting It Up

### Prerequisites

- [Buildwright](https://github.com/raunakkathuria/buildwright) installed
- `git` and `gh` (GitHub CLI) available
- `GITHUB_TOKEN` with `repo` scope for push/PR access

### For Claude Code / OpenCode

```bash
# Install buildwright
curl -sL https://raw.githubusercontent.com/raunakkathuria/buildwright/main/setup.sh | bash

# Generate tool-specific configs
make sync

# Start building
/bw-claw "Add profile photo upload for team members"
```

The `/bw-claw` command handles everything — it reads the Architect persona, decomposes the feature, executes claws sequentially (adopting each persona in turn), and integrates the result.

For true parallel execution, you can run claws in separate terminal sessions or workspaces — each session adopts one claw persona and works its domain. The Architect coordinates via the claw plan and naming conventions.

### For OpenClaw

The recommended approach is the same setup script, which installs the full workflow into your project. For OpenClaw-specific multi-agent setups, you can also install the skill globally:

```bash
mkdir -p ~/.openclaw/skills/buildwright
curl -s https://raw.githubusercontent.com/raunakkathuria/buildwright/main/SKILL.md > ~/.openclaw/skills/buildwright/SKILL.md
```

> **Note:** The global skill provides buildwright's workflow guidance. The slash commands (`/bw-claw`, etc.) require the full project setup via `setup.sh`.

OpenClaw supports multi-agent natively. Configure `openclaw.json` to spawn separate agents per claw:

```json
{
  "agents": {
    "list": [
      { "id": "architect", "name": "Brain", "default": true },
      { "id": "frontend", "name": "UI Claw" },
      { "id": "backend", "name": "API Claw" },
      { "id": "database", "name": "DB Claw" }
    ]
  },
  "tools": {
    "agentToAgent": {
      "enabled": true,
      "allow": ["architect", "frontend", "backend", "database"]
    }
  }
}
```

Example configs for both single-agent and multi-agent setups are in the `examples/` directory of the repo.

## Tool-Agnostic Design

The Claw Architecture is tool-agnostic by design. All configuration lives in `.buildwright/` — a single canonical directory that works with any agentic coding tool.

```
.buildwright/
├── agents/architect.md        ← The brain
├── claws/
│   ├── frontend.md            ← UI specialist
│   ├── backend.md             ← API specialist
│   ├── database.md            ← DB specialist
│   └── TEMPLATE.md            ← Build your own
├── commands/bw-claw.md        ← The multi-agent command
└── steering/
    └── naming-conventions.md  ← Shared vocabulary
```

A sync script (`make sync`) generates tool-specific directories (`.claude/`, `.opencode/`) with path rewriting. Edit `.buildwright/`, run `make sync`, and every tool gets the update. The generated directories are gitignored — only the canonical source is committed.

## What's Next

The Claw Architecture is a pattern, not a product. You can implement it today with any agentic coding tool and Buildwright for quality gates.

We're exploring:
- **Agent Teams RFC** — native OpenClaw support for coordinated multi-agent execution
- **Parallel execution** — claws working simultaneously in separate sessions
- **Claw marketplace** — pre-built claws for common stacks (Next.js, Django, Rails)
- **Cross-repo claws** — monorepo and multi-repo coordination

## Try It

```bash
# Add to any project
curl -sL https://raw.githubusercontent.com/raunakkathuria/buildwright/main/setup.sh | bash

# Set up credentials
export GITHUB_TOKEN=ghp_your_token_here

# Start building
/bw-claw "Add profile photo upload for team members"
```

Or build your own claws for your stack. The pattern is simple:
1. One brain to coordinate (`.buildwright/agents/architect.md`)
2. Specialized claws per domain (`.buildwright/claws/*.md`)
3. Shared naming conventions (`.buildwright/steering/naming-conventions.md`)
4. Buildwright quality gates for every claw

One lobster. Multiple claws. Ship features across your entire stack.

## Links

- [Buildwright](https://github.com/raunakkathuria/buildwright) — Spec-driven autonomous development
- [OpenClaw](https://github.com/openclaw/openclaw) — Personal AI assistant platform
- [Agent Skills](https://agentskills.io) — Cross-tool skill standard
