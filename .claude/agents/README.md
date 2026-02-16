# Agent Personas

This directory contains reusable agent personas that commands can reference.

## Available Agents

| Agent | File | Used By | Key Capabilities |
|-------|------|---------|-------------------|
| Staff Engineer | `staff-engineer.md` | `/bw-new-feature`, `/bw-ship` | Confidence scoring (≥80), HIGH SIGNAL criteria, false-positive exclusions |
| Security Engineer | `bw-security-engineer.md` | `/bw-ship` | Confidence scoring (≥0.8), exploit scenarios, hard exclusions |

## Adding New Agents

1. Create a new file: `[role-name].md`
2. Define:
   - Mindset and expertise
   - What they look for
   - Output format
   - Rules/guidelines
3. Reference in commands via: `Read and adopt persona from .claude/agents/[role-name].md`

## Planned Agents (Future)

| Agent | Purpose |
|-------|---------|
| QA Engineer | Test coverage review, edge case identification |
| Performance Engineer | Performance review, bottleneck identification |
| DevOps Engineer | Infrastructure review, deployment concerns |
| Database Engineer | Schema review, query optimization |
| UX Engineer | API design review, developer experience |
| Technical Writer | Documentation quality |

## Agent Design Principles

1. **Specific expertise** — Each agent has a focused domain
2. **Consistent output** — Predictable format for parsing/automation
3. **Actionable feedback** — Problems come with solutions
4. **Severity levels** — Distinguish blocking from advisory
5. **Context-aware** — Adapt to project type and risk level
