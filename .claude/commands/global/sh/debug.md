---
name: sh-debug
description: "Structured root-cause diagnosis before proposing fixes"
---

# Systematic Debugging

Diagnose bugs, test failures, and unexpected behavior using structured root-cause analysis.
No fixes without understanding. Symptom fixes are failure.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

## When to Use

Any technical issue: test failures, runtime bugs, unexpected behavior, performance problems.
Use ESPECIALLY when under time pressure or when "just one quick fix" seems obvious.

## The Four Phases

Complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

1. **Read error messages carefully** -- full stack traces, line numbers, error codes
2. **Reproduce consistently** -- exact steps, reliable trigger, or gather more data
3. **Check recent changes** -- git diff, new deps, config changes, env differences
4. **Gather evidence at component boundaries** -- log inputs/outputs at each layer
5. **Trace data flow** -- where does the bad value originate? Trace backward to source

### Phase 2: Pattern Analysis

1. **Find working examples** -- similar working code in the same codebase
2. **Compare against references** -- read reference implementations completely
3. **Identify differences** -- list every difference, however small
4. **Understand dependencies** -- components, config, environment assumptions

### Phase 3: Hypothesis and Testing

1. **Form single hypothesis** -- "X is root cause because Y"
2. **Test minimally** -- smallest possible change, one variable at a time
3. **Verify** -- worked? Phase 4. Failed? New hypothesis. Never stack fixes

### Phase 4: Implementation

1. **Create failing test** -- simplest reproduction, automated if possible
2. **Implement single fix** -- address root cause, ONE change, no "while I'm here"
3. **Verify fix** -- test passes, no regressions, issue resolved
4. **If 3+ fixes failed** -- STOP. Question the architecture. Discuss with user

## Red Flags -- STOP and Return to Phase 1

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- Proposing solutions before tracing data flow
- Each fix reveals new problem in different place
- "One more fix attempt" after 2+ failures

## Quick Reference

| Phase | Key Activity | Gate |
|-------|-------------|------|
| 1. Root Cause | Read errors, reproduce, trace | Understand WHAT and WHY |
| 2. Pattern | Find working examples, compare | Identify differences |
| 3. Hypothesis | Form theory, test minimally | Confirmed or new hypothesis |
| 4. Implement | Create test, fix, verify | Bug resolved, tests pass |

## Boundaries

**Will**: Systematic diagnosis, evidence gathering, root-cause identification, targeted fix.
**Will not**: Apply fixes without investigation, stack multiple fixes, skip reproduction.

## Next Step

After diagnosis, apply the fix. Use `/sh:test` to verify. Use `/sh:analyze` if issue reveals broader quality concerns.
