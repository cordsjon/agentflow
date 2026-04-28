---
name: sh:architecture-panel
description: "Multi-expert architecture and solution design review panel with scoring gate and trade-off analysis. Use when reviewing system architecture, service decomposition, data models, integration patterns, or any structural design decision."
needs: [code-context, doc-lookup?]
---

# /sh:architecture-panel — Expert Architecture & Solution Design Review Panel

## Usage

```
/sh:architecture-panel [architecture_content|@file|@diagram] [--mode discussion|critique|socratic] [--evidence passive|active] [--focus domain-modeling|integration|scalability|data-architecture|evolutionary|cloud-native] [--experts "name1,name2"] [--iterations N] [--verbose]
```

## Verbosity

- **Silent (default)**: No expert deliberations. Output only: score table, FIPD-classified findings list, and auto-fix diff. Saves ~60-80% output tokens.
- **Verbose (`--verbose`)**: Full expert deliberations, cross-expert dialogue, reasoning traces, and detailed per-expert analysis before scores and findings.

Silent mode still performs full internal analysis — quality is preserved, only the output is compressed.

## Behavioral Flow

1. **Ingest**: Parse input — detect architecture diagram, ADR, code structure, API spec, or text description
2. **Classify**: Identify architecture style (monolith, microservices, event-driven, serverless) and concerns
3. **Assemble Panel**: Select experts based on `--focus` area or use defaults. `--experts` override replaces defaults entirely. Max 6 experts per review.
4. **Conduct Review**: Run analysis in selected mode using each expert's distinct methodology
5. **Gather Evidence** (if `--evidence active`): Experts inspect code structure, dependency graphs, and configs
6. **Score**: Rate architecture across 5 dimensions (0-10 each), compute overall score
7. **Gate Check**: Overall score must be >= 7.0 to pass. Below threshold = architecture needs rework

## Expert Panel (10 experts)

| Category | Expert | Domain |
|---|---|---|
| Domain & Strategic | Eric Evans | Bounded contexts, ubiquitous language, context mapping, aggregates |
| Domain & Strategic | Vaughn Vernon | Aggregate design, CQRS/ES, domain events, reactive messaging |
| Architecture Fundamentals | Martin Fowler | Architecture patterns, evolutionary design, YAGNI, refactoring |
| Architecture Fundamentals | Neal Ford | Fitness functions, architecture characteristics, evolutionary architecture |
| Architecture Fundamentals | Mark Richards | Architecture patterns, trade-off analysis, architecture decisions |
| Distributed Systems | Gregor Hohpe | Integration patterns, messaging, event-driven, saga orchestration |
| Distributed Systems | Pat Helland | Distributed transactions, immutability, idempotency, eventual consistency |
| Distributed Systems | Sam Newman | Microservice decomposition, service boundaries, API evolution |
| Resilience | Michael Nygard | Stability patterns, failure modes, circuit breakers, capacity planning |
| Evolutionary | Rebecca Parsons | Decision reversibility, architecture governance, emergent design |

## Analysis Modes

### Discussion Mode (`--mode discussion`)
Collaborative architectural exploration. Experts build on each other's insights, explore trade-offs, and propose alternative approaches. Default mode.

### Critique Mode (`--mode critique`)
Systematic review with severity-classified issues (CRITICAL / MAJOR / MINOR). Each finding includes: expert attribution, trade-off analysis, specific recommendation, priority ranking, and quality impact estimate.

### Socratic Mode (`--mode socratic`)
Architecture thinking development. Experts pose probing questions about boundaries, trade-offs, failure modes, and evolution strategy. No direct answers — forces the architect to think critically.

## Evidence Modes

- `--evidence passive` (default): Expert opinions based on provided content only. No tool calls.
- `--evidence active`: Experts inspect code structure, dependency graphs, and configs to verify claims. Produces measurement-backed findings.

## Focus Areas

- **domain-modeling**: Bounded contexts, aggregates, ubiquitous language, context maps. Lead: Eric Evans. Experts: Evans, Vernon, Fowler
- **integration**: Communication patterns, messaging, sagas, API versioning, consistency models. Lead: Gregor Hohpe. Experts: Hohpe, Helland, Newman, Nygard
- **scalability**: Horizontal scaling, stateless design, DB scaling, caching, capacity planning. Lead: Michael Nygard. Experts: Nygard, Newman, Helland, Richards
- **data-architecture**: Data ownership, event sourcing, CQRS, storage selection, migration. Lead: Pat Helland. Experts: Helland, Evans, Vernon, Hohpe
- **evolutionary**: Fitness functions, reversibility, migration paths, technical debt, governance. Lead: Neal Ford. Experts: Ford, Parsons, Fowler, Richards
- **cloud-native**: Cloud services, serverless/container trade-offs, IaC, multi-region, cost. Lead: Mark Richards. Experts: Richards, Nygard, Newman, Parsons

## Scoring Gate

5 dimensions, each scored 0-10:

| Dimension | Description |
|---|---|
| Modularity | Bounded context clarity, service cohesion, coupling minimization |
| Scalability | Horizontal scaling readiness, stateless design, bottleneck absence |
| Resilience | Failure handling, circuit breakers, graceful degradation, recovery |
| Simplicity | Appropriate complexity, YAGNI compliance, clear mental model |
| Evolvability | Decision reversibility, fitness functions, migration readiness |

**Pass threshold: overall score >= 7.0**

Output includes per-dimension scores, overall score, critical issues, expert consensus, trade-off analysis, and improvement roadmap (immediate / short-term / long-term).

## Output

Architecture review document containing:
- Multi-expert analysis with distinct architecture perspectives
- Evidence-backed findings (when `--evidence active`)
- Per-dimension scores and overall quality score
- Pass/fail gate result
- Trade-off analysis for each major decision
- Critical issues with severity and priority
- Consensus points and disagreements
- Priority-ranked improvement recommendations

**SYNTHESIS ONLY** — this panel produces analysis, trade-off evaluation, and recommendations. It does not modify architecture or code without explicit instruction.

**Next Step**: After review, incorporate feedback. Use `/sc:spec-panel --focus architecture` for specification. Use `/sc:security-panel` for security review. Use `/sc:implement` when ready to build.


## Auto-Fix Policy
Fix ALL findings automatically — high, medium, and low severity. Do not ask which findings to fix. Do not present a menu. Fix everything, then report what was changed.
