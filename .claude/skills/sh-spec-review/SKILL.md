---
name: sh:spec-review
description: "Two-stage spec review: quick completeness check then expert panel evaluation. Score >= 7.0 = Ready."
disable-model-invocation: true
---

# Spec Review — Two-Stage Quality Gate

Validate spec documents through a quick review pass followed by an expert panel evaluation. Used by `/sh:brainstorm` after writing a spec, or standalone to assess any spec document.

## Arguments

- `$ARGUMENTS` — path to the spec file to review

## Stage 1: Quick Review (max 5 iterations)

A fast completeness and consistency check. Loops until clean or escalates to human.

### What to Check

| Category | What to Look For |
|----------|------------------|
| Completeness | TODOs, placeholders, "TBD", incomplete sections |
| Coverage | Missing error handling, edge cases, integration points |
| Consistency | Internal contradictions, conflicting requirements |
| Clarity | Ambiguous requirements that could be interpreted multiple ways |
| YAGNI | Unrequested features, over-engineering, gold-plating |
| Scope | Focused enough for a single plan — not covering multiple independent subsystems |
| Architecture | Units with clear boundaries, well-defined interfaces, independently understandable and testable |

### Critical Checks

Look especially hard for:
- Any TODO markers or placeholder text
- Sections saying "to be defined later" or "will spec when X is done"
- Sections noticeably less detailed than others
- Units that lack clear boundaries or interfaces — can you understand what each unit does without reading its internals?

### Stage 1 Output

```markdown
## Spec Review — Stage 1 (Quick)

**File:** <spec-path>
**Iteration:** N/5
**Status:** Approved | Issues Found

**Issues (if any):**
- [Section X]: [specific issue] — [why it matters]

**Recommendations (advisory, non-blocking):**
- [suggestions that don't block approval]
```

### Stage 1 Loop Rules

1. If **Issues Found**: fix them in the spec, then re-run Stage 1
2. If loop reaches **5 iterations** without Approved: **STOP** and surface to human
   > "Stage 1 review has not converged after 5 iterations. Remaining issues: [list]. Please review and advise."
3. If **Approved**: proceed to Stage 2

## Stage 2: Expert Panel

After Stage 1 passes, convene a panel of domain experts to evaluate the spec from multiple perspectives.

### Expert Registry

Read the `experts/` directory in the project root (or `docs/experts/` if present) for available expert profiles. Each expert file defines a persona, domain focus, and evaluation criteria.

If no expert registry exists, use these default panelists:

| Expert | Focus Area | Evaluates |
|--------|-----------|-----------|
| **Architect** | System design | Boundaries, interfaces, scalability, coupling |
| **Security** | Attack surface | Auth, input validation, data exposure, secrets |
| **UX/DX** | Developer & user experience | API ergonomics, error messages, documentation |
| **QA** | Testability | Edge cases, test strategy, failure modes |
| **Pragmatist** | Delivery risk | Scope creep, complexity budget, YAGNI violations |

### Panel Process

1. Each expert reviews the spec independently
2. Each expert produces a score (1-10) and 0-3 issues
3. Aggregate scores into an overall panel score (average)

### Stage 2 Output

```markdown
## Spec Review — Stage 2 (Expert Panel)

**File:** <spec-path>

| Expert | Score | Issues |
|--------|-------|--------|
| Architect | N/10 | [issues or "none"] |
| Security | N/10 | [issues or "none"] |
| UX/DX | N/10 | [issues or "none"] |
| QA | N/10 | [issues or "none"] |
| Pragmatist | N/10 | [issues or "none"] |

**Overall Score:** N.N/10
**Verdict:** Ready | Needs Work

**Blocking Issues:**
- [any issue scored < 5 by any expert]

**Advisory:**
- [non-blocking suggestions]
```

### Scoring Rules

- **Score >= 7.0** — **Ready**. Spec passes. Return to caller.
- **Score < 7.0** — **Needs Work**. List blocking issues. If invoked from `/sh:brainstorm`, return issues for fixing. If standalone, report and stop.
- **Any single expert scores < 5** — that expert's issues are automatically blocking regardless of overall score.

## Integration Points

- **Called by `/sh:brainstorm`** after writing the spec doc (step 7 in brainstorm checklist)
- **Can be invoked standalone**: `/sh:spec-review docs/specs/my-spec.md`
- **Feeds into `/sh:workflow`** — only specs that pass review should produce Ready backlog items
