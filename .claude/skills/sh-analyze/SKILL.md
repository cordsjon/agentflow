---
name: sh:analyze
description: "Code quality, security, and performance scan with FIPD-classified findings"
---

# Code Analysis

Comprehensive code scan across quality, security, performance, and architecture domains.
Findings classified using FIPD taxonomy for actionable triage.

## When to Use

- Code quality assessment for a file, module, or project
- Security vulnerability scanning
- Performance bottleneck identification
- Architecture review and technical debt assessment

## Process

### 1. Scope

Identify the analysis target. Default: entire project.
Determine focus: quality | security | performance | architecture | all.

### 2. Scan

- Read source files in the target scope
- Apply domain-specific pattern matching:
  - **Quality**: code smells, duplication, complexity, naming, dead code
  - **Security**: injection vectors, hardcoded secrets, unsafe deserialization, auth gaps
  - **Performance**: N+1 queries, unbounded loops, missing indexes, memory leaks
  - **Architecture**: circular deps, layer violations, god classes, missing abstractions

### 3. Classify Findings (FIPD Taxonomy)

Every finding gets exactly one classification:

| Class | Meaning | Action |
|-------|---------|--------|
| **F** - Fix | Clear defect with known solution | Apply fix directly |
| **I** - Investigate | Suspicious pattern, root cause unclear | Debug before fixing |
| **P** - Plan | Improvement requiring design work | Create task/US first |
| **D** - Decide | Trade-off requiring human judgment | Present options to user |

### 4. Report

Present findings grouped by FIPD class, then by severity (High/Medium/Low).

```
## Findings

### Fix (3)
- [HIGH] SQL injection in user_search() — src/api/users.py:42
- [MED]  Hardcoded timeout of 30s — src/services/http.py:18
- [LOW]  Unused import — src/utils/helpers.py:3

### Investigate (1)
- [MED]  Memory grows linearly during batch — src/workers/processor.py:88

### Plan (2)
- [MED]  ValidationService bypassed in 3 routes — needs refactor US
- [LOW]  No pagination on /api/items endpoint

### Decide (1)
- [MED]  Sync vs async for external API calls — perf vs complexity trade-off
```

### 5. Summary

End with metrics: total findings, breakdown by class, top 3 recommendations.

## Boundaries

**Will**: Static analysis, pattern detection, severity-rated findings with FIPD classification.
**Will not**: Modify code, run dynamic analysis, or apply fixes (use `/sh:debug` for that).

## Next Step

Review findings. Use `/sh:debug` for Investigation items, create tasks for Plan items.
