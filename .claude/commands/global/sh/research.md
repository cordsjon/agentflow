---
name: sh-research
description: "Use when answering questions that require current external data, competitive intel, technology comparisons, or facts outside training data"
---

# Deep Research

Multi-query web research with source validation and structured evidence synthesis.
Produces a research report -- no implementation.

## When to Use

- Questions beyond knowledge cutoff
- Technical comparison or evaluation
- Best practices and pattern research
- Market/competitive analysis
- Investigating unfamiliar libraries, APIs, or standards

## Process

### 1. Decompose Query (10%)

- Break research question into 3-5 sub-questions
- Identify what types of sources are needed (docs, blog posts, papers, repos)
- Define success criteria: what constitutes a complete answer?

### 2. Parallel Search (50%)

Execute multiple searches concurrently using WebSearch:

```
Query 1: [primary question, direct terms]
Query 2: [alternative phrasing or related angle]
Query 3: [specific sub-question]
```

For each result, use WebFetch to extract key content from the most relevant pages.

### 3. Validate Sources (15%)

- Cross-reference claims across multiple sources
- Prefer: official docs > established blogs > forum answers > AI-generated content
- Note publication dates -- flag stale information
- Flag contradictions explicitly

### 4. Synthesize (25%)

Compile findings into structured report:

```
## Research: [Topic]

### Summary
[2-3 sentence executive summary]

### Findings
#### [Sub-question 1]
- Finding with [source citation]
- Confidence: High/Medium/Low

#### [Sub-question 2]
...

### Contradictions / Open Questions
- [Areas where sources disagree or data is insufficient]

### Sources
1. [Title] - [URL] - [Date] - [Relevance note]
```

## Depth Levels

| Level | Queries | Hops | Output |
|-------|---------|------|--------|
| quick | 2-3 | 1 | Summary paragraph |
| standard | 4-6 | 2-3 | Structured report |
| deep | 8-12 | 3-5 | Detailed analysis with full citations |

## Boundaries

**Will**: Search the web, extract content, cross-validate, produce cited report.
**Will not**: Implement findings, make architectural decisions, access paywalled content, present uncited claims as fact.

## Next Step

After research, user decides action. Use findings to inform implementation or design decisions.
