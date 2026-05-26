---
name: sh-dod
description: Run the Definition of Done gate check before deployment. Verifies work is complete, tests pass, and task meets all exit criteria before committing.
---

# Definition of Done (DOD) Gate

**Gate:** Must pass BEFORE deployment.
An item that fails DOD cannot be deployed. The queue tail enforces this automatically.

## Checklist

### Code Quality
- [ ] **All new code has tests** — every US has a corresponding test file
- [ ] **Tests pass** — project's test suite 100% green
- [ ] **No new test failures** — pre-existing failures documented, zero regressions
- [ ] **Quality audit clean** — analysis returns only Low findings (or none). All findings classified using FIPD taxonomy (Fix/Investigate/Plan/Decide). Investigate/Decide findings must include an `Unknown:` clause
- [ ] **Low findings fixed** — cleanup applied and verified

### Architecture
- [ ] **Service-first** — business logic in service layer, not route handlers
- [ ] **No constraint violations** — checked against project's constraints
- [ ] **Backward compatible** — or all callers updated

### External Writes
- [ ] **Dry-run before mutation** — any write to files outside current task scope MUST preview changes before executing

### Committed
- [ ] **Clean commit** — descriptive message, atomic scope
- [ ] **No uncommitted changes** — `git status` clean after commit
- [ ] **No secrets** — no credentials, API keys, or tokens in committed code
- [ ] **Pre-commit hooks pass** — all configured hooks green

### Deployable
- [ ] **Application starts** — server responds, no crash on boot
- [ ] **Existing functionality intact** — no regressions

### Verification
- [ ] **Verification pass** — run with evidence (test output, screenshots) before marking task done

### Pipeline Housekeeping
- [ ] **Queue item checked** — `[x]` in TODO-Today.md
- [ ] **DONE-Today updated** — item moved with timestamp
- [ ] **BACKLOG updated** — source item marked completed or removed

## Enforcement (Mandatory Queue Tail)

```
1. Analyze changed files (findings use FIPD classification)
2. Deep audit (M+ size tasks only -- security/perf/architecture)
3. Cleanup (fix Low findings, enforce coding standards)
4. Run tests with coverage (if new test files)
5. Atomic conventional commit
6. Deploy (project-specific)
```

If any step fails, autopilot pauses and reports the blocker.
