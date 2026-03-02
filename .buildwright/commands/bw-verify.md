---
name: bw-verify
description: Run quick quality checks (typecheck, lint, test, build). For full checks including security and AI review, use /bw-ship.
---

Running quick verification...

## 1. Discover Project Commands

First, check the project for available commands:
- package.json scripts
- Cargo.toml
- Makefile
- pyproject.toml
- go.mod

Document findings in .buildwright/steering/tech.md if not already present.

---

## 2. Type Check

```bash
# Node/TypeScript
npm run typecheck || npx tsc --noEmit

# Rust
cargo check

# Go
go build ./...

# Python
mypy . || pyright
```

**Result:** PASS / FAIL
**Details:** [error count and locations if failed]

---

## 3. Lint

```bash
# Node/TypeScript
npm run lint || npx eslint .

# Rust
cargo clippy -- -D warnings

# Go
golangci-lint run

# Python
ruff check . || flake8
```

**Result:** PASS / FAIL
**Details:** [warning/error count]

---

## 4. Tests

```bash
# Node/TypeScript
npm test

# Rust
cargo test

# Go
go test ./...

# Python
pytest
```

**Result:** PASS / FAIL
**Details:** [test count, coverage % if available]

---

## 5. Build

```bash
# Node/TypeScript
npm run build

# Rust
cargo build --release

# Go
go build ./...

# Python
# Usually no build step, skip
```

**Result:** PASS / FAIL
**Details:** [any warnings]

---

## Summary

```
╔═══════════════════════════════════════════════════════════════╗
║                    QUICK VERIFICATION                         ║
╠═══════════════════════════════════════════════════════════════╣
║  Type Check:  ✅ PASS / ❌ FAIL                               ║
║  Lint:        ✅ PASS / ❌ FAIL  ([N] warnings)               ║
║  Tests:       ✅ PASS / ❌ FAIL  ([N] tests, [X]% coverage)   ║
║  Build:       ✅ PASS / ❌ FAIL                               ║
╠═══════════════════════════════════════════════════════════════╣
║  Status: PASS / BLOCKED                                       ║
╚═══════════════════════════════════════════════════════════════╝
```

If BLOCKED: List specific failures with file:line references.

---

## Next Steps

- If PASS: Run `/bw-ship` for full quality pipeline (security + review + release)
- If BLOCKED: Fix issues and re-run `/bw-verify`
