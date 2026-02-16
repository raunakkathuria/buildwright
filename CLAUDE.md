# Buildwright Development

## Mission
Agent-first autonomous development. Humans approve specs; agents implement, test, and ship.

## Steering Documents
@.claude/steering/product.md
@.claude/steering/tech.md
@.claude/steering/quality-gates.md

## Operating Mode

### Default Behavior
- AUTONOMOUS mode: Execute fully without asking for confirmation
- Verify your own work through tests and checks
- Commit when verification passes
- Only stop if genuinely blocked (missing info, failing tests after retries)
- **Autonomous failure handling**: When `BUILDWRIGHT_AUTO_APPROVE=true` (default) and any step fails after retries, commit completed work, push, create PR with failure details, and exit(1). In interactive mode (`BUILDWRIGHT_AUTO_APPROVE=false`), STOP and report blocker as before.

### Workflow Priority
1. **New features**: /bw-new-feature → Research → Spec → Approval → Implement → Ship
2. **Small tasks/bugs**: /bw-quick → Quick research → Implement → Verify → Commit
3. **Refactors**: /bw-new-feature (if scope unclear) or /bw-quick (if scope clear)
4. **Ship existing work**: /bw-ship → Verify → Security → Review → Push → PR
5. **Quick quality check**: /bw-verify → typecheck, lint, test, build

## Command Discovery
When you need project commands:
1. Check package.json / Cargo.toml / pyproject.toml / go.mod / Makefile
2. Check .github/workflows/ for expected command sequence
3. Document discovered commands in .claude/steering/tech.md

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `BUILDWRIGHT_AUTO_APPROVE` | `true` | Autonomous mode — skip human approval, fail gracefully on errors |
| `BUILDWRIGHT_AGENT_RETRIES` | `2` | Number of verify retries before giving up |

## Verification Loop (CRITICAL)
Before EVERY commit, run the project's verification commands:
```bash
# Adapt these to the project - discover actual commands first
npm run typecheck   # or tsc, cargo check, go build, etc.
npm run lint        # or eslint, cargo clippy, golangci-lint, etc.
npm run test        # or jest, cargo test, go test, pytest, etc.
npm run build       # production build must succeed
```

If ANY fail: fix and retry (max 2 attempts). If same error repeats or still failing: STOP and report blocker.

## Git Rules
- Atomic commits: only commit files you changed
- Conventional commits: feat:, fix:, refactor:, test:, docs:, chore:
- List each file explicitly in commit message
- Never edit .env files
- Never run destructive git operations without explicit instruction
- Multi-agent safety: NEVER use git stash (other agents may be working)

## Design Principles (ALWAYS APPLY)

1. **KISS (Keep It Simple, Stupid)**
   - Prefer simple solutions over clever ones
   - If it feels complex, step back and simplify
   - Code should be readable by a junior developer

2. **YAGNI (You Aren't Gonna Need It)**
   - Build only what's required NOW
   - No speculative features "for later"
   - Avoid abstractions until they're proven needed

3. **No Premature Optimization**
   - Make it work first, then make it fast (if needed)
   - Optimize only with profiling data
   - Readability > micro-optimizations

4. **Boring Technology**
   - Prefer proven, well-documented solutions
   - New tech only when it solves a real problem
   - Consider maintenance burden

5. **Fail Fast, Fail Loud**
   - Validate inputs at boundaries
   - Throw errors early with clear messages
   - No silent failures

## Code Standards
- Follow existing patterns in the codebase exactly
- Keep files under 500 lines; split proactively
- Write tests for all new functionality (TDD preferred)
- No `any` types in TypeScript
- Use Decimal/BigDecimal for financial calculations, NEVER floating point
- All user inputs must be validated

## Self-Improvement
When you discover a pattern, gotcha, or better approach:
- Add it below under "Learned Patterns"
- Keep entries concise (one line each)

## Learned Patterns
<!-- Agent adds entries here as it learns -->

