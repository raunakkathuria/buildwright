# Quality Gates

These automated gates replace human code review. ALL must pass for merge.

## Gate 1: Static Analysis
- [ ] Type check passes (zero errors)
- [ ] Lint passes (zero errors, warnings acceptable)
- [ ] No new lint warnings introduced

## Gate 2: Tests
- [ ] All existing tests pass
- [ ] New code has tests
- [ ] Coverage does not decrease
- [ ] Critical paths have >80% coverage

## Gate 3: Security
- [ ] No high/critical vulnerabilities in dependencies
- [ ] No secrets in code
- [ ] SAST scan passes (if configured)

## Gate 4: Build
- [ ] Production build succeeds
- [ ] No build warnings

## Gate 5: AI Review (Optional)
- [ ] No blocking issues from AI reviewer

## Financial/Trading Code (Additional)
- [ ] No floating-point for currency
- [ ] All inputs validated
- [ ] Rate limiting on sensitive endpoints
- [ ] Audit logging for transactions

## Auto-Merge Criteria
When ALL gates pass → PR auto-merges → Deploy triggers
