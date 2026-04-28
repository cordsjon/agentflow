---
name: sh:test-panel
description: "Multi-expert test strategy panel with pyramid analysis, risk-based coverage review, scoring gate, and toolchain dispatch. Use when reviewing test strategy, planning tests for new features, analyzing test pyramid shape, or evaluating test coverage approach."
needs: [code-context, doc-lookup?]
---

# /sh:test-panel — Expert Test Strategy & Pyramid Review Panel

## Usage

```
/sh:test-panel [test_content|@file|@codebase] [--mode review|plan|plan-and-execute|debate] [--evidence passive|active] [--focus pyramid-shape|boundary-testing|automation-roi|risk-coverage|observability-and-production|test-design-quality|feedback-loop] [--experts "name1,name2"] [--iterations N] [--verbose]
```

## Verbosity

- **Silent (default)**: No expert deliberations. Output only: score table, FIPD-classified findings list, and auto-fix diff. Saves ~60-80% output tokens.
- **Verbose (`--verbose`)**: Full expert deliberations, cross-expert dialogue, reasoning traces, and detailed per-expert analysis before scores and findings.

Silent mode still performs full internal analysis — quality is preserved, only the output is compressed.

## Behavioral Flow

1. **Ingest**: Parse input — detect test files, coverage reports, code structure, feature description, or test strategy document
2. **Context Gather**: Use `run_pipeline` with `include_tests: true` to gather codebase test structure
3. **Classify**: Identify current test landscape (pyramid shape, test types, coverage gaps, framework)
4. **Assemble Panel**: Select experts based on `--focus` area or use defaults. `--experts` override replaces defaults entirely. Max 6 experts per review.
5. **Conduct Review**: Run analysis in selected mode using each expert's distinct methodology
6. **Gather Evidence** (if `--evidence active`): Experts inspect test files, coverage reports, CI configs, observability setup
7. **Score**: Rate test strategy across 7 dimensions (0-10 each), compute overall score
8. **Gate Check**: Overall score must be >= 7.0 to pass. Below threshold = test strategy needs rework. **HARD-BLOCKING for DoR/DoD.**
9. **Dispatch** (plan-and-execute mode only): Generate dispatch manifest and invoke execution skills

## Expert Panel (12 experts)

| Category | Expert | Domain |
|---|---|---|
| TDD & Unit Testing | Kent Beck | TDD, unit testing philosophy, simple design, red-green-refactor |
| TDD & Unit Testing | Jessica Kerr | Property-based testing, generative testing, invariant verification |
| Test Strategy | Lisa Crispin | Agile testing quadrants, whole-team quality, business-facing tests |
| Test Strategy | Janet Gregory | Test strategy planning, whole-team quality ownership |
| Test Architecture | Martin Fowler | Test pyramid, test doubles, sociable vs. solitary unit tests |
| Test Architecture | Dave Farley | Continuous delivery, deployment pipelines, feedback loops |
| Legacy Code | Michael Feathers | Legacy code testing, test seams, dependency breaking |
| Exploratory Testing | James Bach | Exploratory testing, risk-based testing, context-driven testing |
| Exploratory Testing | Michael Bolton | Test oracles, sapient testing, testing vs. checking |
| Automation Strategy | Angie Jones | Test automation architecture, visual testing, automation ROI |
| Contract Testing | Sam Newman | Consumer-driven contracts, microservice testing, API evolution |
| Observability | Charity Majors | Testing in production, observability-driven development, canary deploys |

## Analysis Modes

### Review Mode (`--mode review`)
Evaluate existing test strategy/codebase. Scored findings. Pure advisory.

### Plan Mode (`--mode plan`)
Generate test strategy for new feature/project. Advisory output only.

### Plan-and-Execute Mode (`--mode plan-and-execute`)
Same as `plan`, but after score ≥ 7.0, dispatches execution skills with concrete tasks.

**Dispatch Targets:**

| Skill | When Dispatched |
|---|---|
| **`sh:tdd`** | Writing new tests — panel provides specific test description and approach |
| **`sc:test`** | Running existing tests, coverage analysis, gap identification |
| **`sh:test`** | Execution + coverage reporting after new tests written |
| **`sh:parallel`** | Multiple independent test tasks can run concurrently |
| **`sh:verify`** | Final verification that strategy was actually implemented |

**Note:** `sh:dor` and `sh:dod` are NOT dispatch targets. They call the test-panel, not the reverse.

### Debate Mode (`--mode debate`)
Adversarial — experts disagree. Stress-tests assumptions. No score produced. Not usable as DoR/DoD gate.

## Evidence Modes

- `--evidence passive` (default): Expert opinions based on provided content only. No tool calls.
- `--evidence active`: Experts inspect test files, coverage reports, CI configuration, observability setup.

## Focus Areas

- **pyramid-shape**: Test distribution across layers. Lead: Fowler. Experts: Fowler, Beck, Farley, Crispin
- **boundary-testing**: Service boundaries, API contracts, integration seams. Lead: Newman. Experts: Newman, Feathers, Majors
- **automation-roi**: Automation vs. manual allocation, maintenance cost, flaky tests. Lead: Jones. Experts: Jones, Bach, Bolton, Gregory
- **risk-coverage**: Risk-based prioritization, blind spots, oracle quality. Lead: Bach. Experts: Bach, Bolton, Crispin, Majors
- **observability-and-production**: Production monitoring, feature flags, canary deploys. Lead: Majors. Experts: Majors, Farley, Newman
- **test-design-quality**: Behavior vs. implementation testing, determinism, mock usage. Lead: Beck. Experts: Beck, Kerr, Feathers, Jones
- **feedback-loop**: CI speed, local dev loop, deploy confidence. Lead: Farley. Experts: Farley, Beck, Majors

## Scoring Gate

7 dimensions, each scored 0-10:

| Dimension | Description |
|---|---|
| Pyramid Balance | Distribution across test layers, healthy ratio |
| Risk Alignment | High-risk paths tested proportionally |
| Boundary Coverage | Service boundaries, API contracts tested |
| Automation Fitness | Right things automated, maintainable |
| Feedback Speed | Fast, reliable signal from test suite |
| Observability Readiness | Production monitoring complements pre-deploy tests |
| Test Design Quality | Behavior-focused, readable, deterministic tests |

**Pass threshold: overall score >= 7.0**

Output includes per-dimension scores, overall score, blocking gaps (on FAIL), dispatch manifest (on PASS in plan-and-execute mode), expert consensus, and improvement roadmap.

## DoR/DoD Integration (HARD-BLOCKING)

- **`sh:dor`**: Invokes test-panel in `plan` mode. Score < 7.0 = **FAIL — cannot proceed to implementation.**
- **`sh:dod`**: Invokes test-panel in `review` mode. Score < 7.0 = **FAIL — cannot merge/deploy.**
- Direction is one-way: DoR/DoD call test-panel. Test-panel never dispatches to DoR/DoD.

## Output

Test strategy review document containing:
- Multi-expert analysis with distinct testing perspectives
- Evidence-backed findings (when `--evidence active`)
- Per-dimension scores and overall quality score
- Pass/fail gate result with blocking gaps on failure
- Dispatch manifest with concrete tasks (plan-and-execute mode)
- Expert consensus and disagreements
- Priority-ranked improvement recommendations

**SYNTHESIS + DISPATCH, NOT IMPLEMENTATION** — this panel designs test strategy and dispatches execution skills. It does not write test code itself.

**Next Step**: After review, use `sh:tdd` for test-driven development. Use `sc:test` for test execution. Use `sh:verify` for final verification.

## Auto-Fix Policy
Fix ALL findings automatically — high, medium, and low severity. Do not ask which findings to fix. Do not present a menu. Fix everything, then report what was changed.
