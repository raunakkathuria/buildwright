# Naming Conventions

Shared vocabulary across all agents and claws. When any agent adds a new field, endpoint, or concept, it MUST be registered here so all other agents derive their naming from this registry.

## Layer-Specific Naming Rules

| Layer | Convention | Example |
|-------|-----------|---------|
| Database columns | `snake_case` | `photo_url`, `created_at` |
| API (JSON keys) | `camelCase` | `photoUrl`, `createdAt` |
| UI (JavaScript) | `camelCase` | `photoUrl`, `createdAt` |
| CSS classes | `kebab-case` | `photo-upload`, `member-card` |
| URL paths | `kebab-case` | `/api/team-members/:id/photo` |
| Environment vars | `SCREAMING_SNAKE` | `BUILDWRIGHT_AUTO_APPROVE` |
| File names | `kebab-case` | `photo-upload.tsx`, `team-members.ts` |

## Canonical Field Registry

Register new fields here when they cross domain boundaries.

| Concept | Database | API (JSON) | UI (JS) | Notes |
|---------|----------|------------|---------|-------|
| — | `snake_case` | `camelCase` | `camelCase` | Convention |
<!-- Add new fields below this line -->

## Canonical Endpoint Registry

Register new endpoints here when they're defined by the Architect.

| Purpose | Method | Path | Request Body | Response Body |
|---------|--------|------|-------------|--------------|
<!-- Add new endpoints below this line -->

## Rules

1. **Architect registers first** — Before spawning claws, the Architect adds new fields/endpoints to this file
2. **Claws derive, never invent** — Each claw looks up naming from this registry, never creates its own
3. **One source of truth** — If a name isn't here, ask the Architect before proceeding
4. **No abbreviations** — Use `photo_url` not `pic_url`, `description` not `desc`
5. **Consistent pluralization** — Collections are plural (`members`), single items are singular (`member`)
