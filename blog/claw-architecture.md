# The Claw Architecture: Multi-Agent AI Development with OpenClaw + Buildwright

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

One lobster (OpenClaw instance) with multiple specialized claws (agents).

Each claw is an expert at grabbing work in its domain:

- **UI Claw**: Knows React patterns, component libraries, accessibility, state management
- **API Claw**: Knows REST conventions, OpenAPI specs, authentication, error handling
- **DB Claw**: Knows schema design, migrations, indexing, query optimization

The Brain (Architect) coordinates everything — analyzing requirements, creating plans, spawning claws, and combining results.

## The Anatomy

| Lobster Part | Architecture Role |
|---|---|
| Brain | Architect Agent — analyzes, plans, coordinates |
| Claws | Specialized Agents — grab and execute domain-specific work |
| Nervous System | OpenClaw Gateway — handles communication between claws |
| Shell | Buildwright — protects quality through verify, security, review |

## How It Works

### Step 1: You Request a Feature

```
You (Telegram): "Add profile photo upload for team members"
```

### Step 2: Brain Analyzes

The Architect Agent reads your system architecture and determines which claws need to grab work:

```
ARCHITECT: This feature touches:
- Database (store photo URL)
- API (upload endpoint)
- UI (upload component)

Creating plan...
```

### Step 3: Brain Spawns Claws

Each claw gets spawned with its specific task:

```
🗄️ DB CLAW: "Add photo_url column to members table"
⚙️ API CLAW: "Add POST /api/members/:id/photo endpoint"
🎨 UI CLAW: "Add PhotoUpload component to MemberCard"
```

### Step 4: Claws Grab and Execute

Each claw:
1. Reads its domain (schema, routes, components)
2. Plans the changes
3. Implements with TDD
4. Verifies its work
5. Reports back to Brain

```
🗄️ DB CLAW: ✅ Migration created, photo_url column added
⚙️ API CLAW: ✅ Upload endpoint ready, validates jpg/png, 2MB max
🎨 UI CLAW: ✅ PhotoUpload component added, drag-and-drop works
```

### Step 5: Brain Combines and Ships

```
ARCHITECT: All claws complete.
- Running integration test... ✅
- Security scan... ✅
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
│  /bw-security  → OWASP scan, secrets detection              │
│  /bw-review    → Staff Engineer code review                 │
│  /bw-ship      → Full pipeline to PR                        │
└─────────────────────────────────────────────────────────────┘
```

Each claw verifies its work. The brain does integration verification at the end.

## Shared Vocabulary: Naming Conventions

Claws need to speak the same language. When the DB Claw adds `photo_url`, the API Claw must know it's `photoUrl`, and the UI Claw must use `photoUrl`.

A shared `naming-conventions.md` keeps everyone aligned:

```
## Canonical Field Registry

| Concept | Database | API | UI |
|---------|----------|-----|-----|
| photo_url | photo_url | photoUrl | photoUrl |
| created_at | created_at | createdAt | createdAt |

When adding a new field, the Brain registers it here first.
All claws derive their naming from this registry.
```

## When to Use Claw Architecture

| Project Type | Approach |
|---|---|
| Small/Demo | Single agent + Buildwright |
| Medium (growing) | 2-3 claws (Frontend, Backend, Database) |
| Enterprise | 5+ claws (UI, API, Gateway, DB, Business, Security) |

Start simple. Add claws as complexity grows.

## Setting It Up

### Prerequisites
- OpenClaw installed (or Claude Code / OpenCode)
- Buildwright skill

### 1. Create Workspaces (OpenClaw)

```bash
# Brain (Architect)
mkdir -p ~/.openclaw/workspace-architect/skills/buildwright

# Claws
mkdir -p ~/.openclaw/workspace-frontend/skills/buildwright
mkdir -p ~/.openclaw/workspace-backend/skills/buildwright
mkdir -p ~/.openclaw/workspace-database/skills/buildwright
```

### 2. Configure OpenClaw

```json
// ~/.openclaw/openclaw.json
{
  "agents": {
    "list": [
      { "id": "architect", "name": "Brain", "default": true,
        "workspace": "~/.openclaw/workspace-architect" },
      { "id": "frontend", "name": "UI Claw",
        "workspace": "~/.openclaw/workspace-frontend" },
      { "id": "backend", "name": "API Claw",
        "workspace": "~/.openclaw/workspace-backend" },
      { "id": "database", "name": "DB Claw",
        "workspace": "~/.openclaw/workspace-database" }
    ]
  },
  "tools": {
    "agentToAgent": { "enabled": true,
      "allow": ["architect", "frontend", "backend", "database"] }
  }
}
```

### 3. Add Buildwright Skill to Each

```bash
for workspace in architect frontend backend database; do
  cp SKILL.md ~/.openclaw/workspace-$workspace/skills/buildwright/SKILL.md
done
```

### 4. Use with Claude Code or OpenCode

The same pattern works — claws run as sequential persona switches (single agent) or parallel terminal sessions:

```bash
# Claude Code
/bw-claw "Add profile photo upload"

# OpenCode
/bw-claw "Add profile photo upload"
```

## What's Next

The Claw Architecture is a pattern, not a product. You can implement it today with:
- Any agentic coding tool (Claude Code, OpenCode, OpenClaw)
- Buildwright for quality gates
- Any messaging channel (Telegram, Slack, Discord) for OpenClaw

We're exploring:
- **Agent Teams RFC** — native OpenClaw support for coordinated multi-agent
- **Parallel execution** — claws working simultaneously
- **Claw marketplace** — pre-built claws for common stacks (Next.js, Django, Rails)

## Try It

```bash
# Add to any project
curl -sL https://raw.githubusercontent.com/raunakkathuria/buildwright/main/setup.sh | bash

# Start building
/bw-claw "Add profile photo upload for team members"
```

Or build your own claws for your stack. The pattern is simple:
1. One brain to coordinate
2. Specialized claws per domain
3. Shared naming conventions
4. Buildwright for quality

One lobster. Multiple claws. Ship features across your entire stack.

## Links

- [Buildwright](https://github.com/raunakkathuria/buildwright) — Spec-driven autonomous development
- [OpenClaw](https://github.com/openclaw/openclaw) — Personal AI assistant platform
- [Agent Skills](https://agentskills.io) — Cross-tool skill standard
