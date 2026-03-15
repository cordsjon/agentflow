---
name: sh:explain
description: "Educational code explanations with adaptive depth and insight highlights"
---

# Code Explanation

Clear, educational explanations of code, concepts, and system behavior.
Adapts depth to the user's expertise level. Highlights key insights.

## When to Use

- Understanding unfamiliar code or modules
- Learning how a system or subsystem works
- Explaining architectural patterns or design decisions
- Knowledge transfer and onboarding context

## Process

### 1. Assess Target

- Read the code/component to explain
- Identify its purpose, inputs, outputs, and side effects
- Map dependencies and callers

### 2. Gauge Depth

Adapt to user's apparent level (or explicit request):

| Level | Style |
|-------|-------|
| **basic** | Analogy-first, minimal jargon, step-by-step walkthrough |
| **intermediate** | Pattern names, design rationale, trade-offs discussed |
| **advanced** | Implementation details, edge cases, performance implications |

### 3. Structure Explanation

Use progressive disclosure -- start with the "what" before the "how":

1. **Purpose** -- What does this do and why does it exist?
2. **How it works** -- Walk through the logic flow
3. **Key decisions** -- Why was it built this way? What are the trade-offs?
4. **Connections** -- How does it fit into the larger system?

### 4. Highlight Insights

Use Insight boxes for key teaching points:

```
> INSIGHT: The retry logic uses exponential backoff because fixed intervals
> cause thundering herd problems when multiple clients reconnect simultaneously.
```

Use these sparingly (1-3 per explanation) for genuinely non-obvious points.

### 5. Provide Examples

- Show concrete usage examples when helpful
- For complex logic, trace through with sample data
- Compare with simpler alternatives to show why the chosen approach matters

## Output Format

```
## [Component/Concept Name]

**Purpose**: [One sentence]

**How it works**:
[Explanation at appropriate depth]

> INSIGHT: [Key non-obvious point]

**Example**:
[Concrete usage or data trace]

**Connections**: Used by [X], depends on [Y], related to [Z].
```

## Boundaries

**Will**: Explain code, concepts, patterns, and architecture with educational clarity.
**Will not**: Modify code, refactor, or implement changes. Explanation only.

## Next Step

After understanding, use `/sh:analyze` to assess quality or proceed with implementation.
