# DOD Checklist (Printable)

## Code Quality
```
[ ] All new code has tests
[ ] Tests pass (100% green)
[ ] No new test failures (zero regressions)
[ ] Quality audit clean (FIPD classified, Low only)
[ ] Low findings fixed
```

## Architecture
```
[ ] Service-first (logic in service layer)
[ ] No constraint violations
[ ] Backward compatible (or callers updated)
```

## External Writes
```
[ ] Dry-run before mutation (preview changes first)
```

## Committed
```
[ ] Clean commit (descriptive, atomic)
[ ] No uncommitted changes
[ ] No secrets in code
[ ] Pre-commit hooks pass
```

## Deployable
```
[ ] Application starts
[ ] Existing functionality intact
```

## Verification
```
[ ] Verification pass with evidence
```

## Pipeline Housekeeping
```
[ ] Queue item checked [x]
[ ] DONE-Today updated with timestamp
[ ] BACKLOG source item updated
```
