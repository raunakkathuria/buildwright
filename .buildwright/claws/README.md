# Claw Templates

Domain-specialist agent templates for the Claw Architecture.

## Concept

Each "claw" is a domain-expert agent that grabs work in its area. The Architect (brain) spawns claws, defines interfaces between them, and combines their results.

```
                    🧠 Architect (Brain)
                         │
           ┌─────────────┼─────────────┐
           │             │             │
        🎨 UI         ⚙️ API        🗄️ DB
        Claw          Claw          Claw
```

## Available Claws

| Claw | File | Domain | Typical Directories |
|------|------|--------|-------------------|
| Frontend | `frontend.md` | UI components, state, routing | `ui/`, `frontend/`, `src/components/` |
| Backend | `backend.md` | API endpoints, middleware, auth | `api/`, `server/`, `src/routes/` |
| Database | `database.md` | Schema, migrations, queries | `database/`, `migrations/`, `prisma/` |
| DevOps/SRE | `devops.md` | Infrastructure | `k8s/`, `helm/`, `infra/`, `Dockerfile` |

## Adding a New Claw

1. Copy `TEMPLATE.md` to `[domain].md`
2. Fill in domain-specific expertise, patterns, and conventions
3. Reference from the Architect agent or `/bw-claw` command

## How Claws Work

1. **Architect** analyzes the feature and decomposes into claw tasks
2. Each claw receives: task description + interface contract + naming conventions
3. Each claw: reads its domain → plans → implements with TDD → verifies
4. **Architect** combines results → runs integration checks → ships

## Claw Design Principles

1. **Domain isolation** — Each claw only reads/writes its own domain
2. **Interface contracts** — Claws communicate through defined APIs, not shared state
3. **Independent verification** — Each claw verifies its work before reporting back
4. **Shared vocabulary** — All claws use the naming conventions defined by the Architect
5. **Buildwright quality gates** — Every claw uses /bw-verify for its domain

## When to Use Claws vs Single Agent

| Scenario | Approach |
|----------|----------|
| Single-domain change | `/bw-quick` or `/bw-new-feature` |
| Cross-domain, small scope | `/bw-new-feature` (sequential) |
| Cross-domain, large scope | `/bw-claw` (multi-agent) |
| Greenfield with multiple layers | `/bw-claw` from the start |
| Containerize app or add local k8s | `/bw-claw "containerize with Docker and local k8s"` |

## Tool-Specific Execution

### Claude Code
Claws run as sub-agents via the Task tool or parallel terminal sessions:
```bash
# Terminal 1: UI Claw
claude --agent .buildwright/claws/frontend.md

# Terminal 2: API Claw
claude --agent .buildwright/claws/backend.md
```

### OpenCode
Claws run as custom agents defined in `.opencode/agents/`:
```bash
# Each claw is an agent with specific tools
opencode --agent frontend
opencode --agent backend
```

### OpenClaw
Claws run as separate workspace agents via `openclaw.json`:
```json
{
  "agents": {
    "list": [
      { "id": "frontend", "workspace": "~/.openclaw/workspace-frontend" },
      { "id": "backend", "workspace": "~/.openclaw/workspace-backend" }
    ]
  }
}
```
