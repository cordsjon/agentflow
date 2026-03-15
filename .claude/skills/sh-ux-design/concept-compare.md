# Concept Comparison Template

When multiple wireframe concepts exist (Phase 7), generate this comparison to support the decision.

## Comparison Table

```markdown
## Wireframe Concept Comparison: <feature>

| Dimension              | Concept A: <name>  | Concept B: <name>  | Concept C: <name> |
|------------------------|--------------------|--------------------|--------------------|
| **Interaction model**  | e.g., step wizard  | e.g., chat-based   | e.g., single page  |
| **Screen count**       |                    |                    |                    |
| **Clicks to complete** |                    |                    |                    |
| **Form inputs**        |                    |                    |                    |
| **Required decisions** |                    |                    |                    |
| **Skip paths**         |                    |                    |                    |
| **Drop-off risk**      | High/Medium/Low    | High/Medium/Low    | High/Medium/Low    |
| **JTBD fit**           | Does job get done?  |                    |                    |
| **ICP complexity**     | Matches user level? |                    |                    |
| **Fallback paths**     | What if X fails?    |                    |                    |
| **Competitive delta**  | vs. competitor step count |              |                    |
```

## Decision Criteria (rank by priority)

1. **JTBD completion** — does the user finish the job in every path?
2. **Friction** — fewer clicks, fewer decisions, fewer form fields wins
3. **Drop-off risk** — which concept has the lowest abandonment probability?
4. **ICP match** — complexity level appropriate for target user?
5. **Technical feasibility** — can the target stack support this interaction model?
6. **Fallback resilience** — what happens when an integration fails?

## Optional: Business Panel Validation

For strategic features, run the comparison through the business panel:

```
/sh:business-panel docs/wireframe-comparison-<feature>.md --focus growth --mode debate
```

The panel provides expert perspectives on which concept better serves strategy. Useful when the decision isn't obvious from metrics alone.

## Decision Format

After comparison, document the decision:

```markdown
## Decision: <feature> wireframe concept

**Chosen:** Concept <X> — <name>
**Reason:** <1-2 sentences — why this concept wins>
**Trade-off accepted:** <what the losing concept did better>
**Action:** Merge wireframe/<feature>-concept-<x>, delete other branches
```

Save to `docs/wireframe-<feature>-decision.md`.
