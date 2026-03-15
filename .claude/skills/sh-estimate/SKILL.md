---
name: sh:estimate
description: "Development effort estimation with T-shirt sizing and risk adjustment"
---

# Effort Estimation

Estimate development effort for tasks, features, or projects.
T-shirt sizing aligned with task management. Risk-adjusted.

## When to Use

- Sizing a new feature or user story before committing
- Comparing effort across multiple options
- Planning sprints or task queues
- Assessing feasibility of a proposed change

## Process

### 1. Scope Analysis

- Read relevant code to understand current state
- Identify what needs to change (files, modules, interfaces)
- List dependencies and integration points
- Note unknowns and assumptions

### 2. Decompose Work

Break into concrete sub-tasks:

```
1. [Sub-task] — [what changes]
2. [Sub-task] — [what changes]
3. Tests — [scope of test coverage needed]
4. Integration — [what needs wiring up]
```

### 3. Size Each Sub-task

| Size | Meaning | Typical Scope |
|------|---------|---------------|
| **S** | Contained change | Single file, clear pattern, < 1 hour |
| **M** | Multi-file change | 2-5 files, some design needed, 1-4 hours |
| **L** | Cross-cutting change | 5+ files, new patterns, 4-16 hours |
| **XL** | Requires breakdown | Too large for single task -- split first |

### 4. Risk Adjustment

Identify risk factors that increase effort:

| Risk Factor | Multiplier |
|-------------|-----------|
| Unfamiliar code area | 1.5x |
| No existing tests | 1.3x |
| External API dependency | 1.5x |
| Database migration | 1.3x |
| Cross-platform concerns | 1.5x |
| Unclear requirements | 2x |

Apply the highest applicable multiplier (don't stack).

### 5. Present Estimate

```
## Estimate: [Feature/Task Name]

### Sub-tasks
| # | Task | Size | Risk | Adjusted |
|---|------|------|------|----------|
| 1 | [task] | M | Unfamiliar (1.5x) | M-L |
| 2 | [task] | S | None | S |
| 3 | Tests | M | No existing (1.3x) | M |

### Overall: [M-L]
### Confidence: [High/Medium/Low]
### Key Assumptions: [list]
### Unknowns: [list — each unknown reduces confidence]
```

## Boundaries

**Will**: Analyze scope, decompose work, size tasks, identify risks, present estimate.
**Will not**: Execute the work, create timelines, make commitments, or start implementation.

## Next Step

After estimation, user decides priority and scheduling. Proceed with implementation when ready.
