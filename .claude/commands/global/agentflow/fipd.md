---
name: agentflow-fipd
description: Classify findings using the FIPD taxonomy (Fix/Investigate/Plan/Decide) instead of severity-only ratings. Background knowledge for all analysis and audit skills.
user-invocable: false
---

# FIPD Finding Taxonomy

Every finding gets classified by **action type** — what the reader should do next, not just how bad it is.

## The Four Actions

| Action | Definition | What to Do |
|--------|-----------|------------|
| **Fix** | Root cause known, solution clear | Implement immediately |
| **Investigate** | Symptom observed, root cause unknown | Gather data, reproduce, diagnose |
| **Plan** | Issue understood, direction known but requires design | Add to backlog, estimate, schedule |
| **Decide** | Trade-off identified, multiple valid directions | Escalate to human decision-maker |

## Rules

1. **Every finding gets exactly one FIPD classification** — never leave findings unclassified
2. **Fix items go directly to TODO-Today** — no backlog detour needed
3. **Investigate items get a timebox** — max 1 hour before escalation
4. **Plan items go to BACKLOG#Ideation** — they need design work before implementation
5. **Decide items surface immediately to user** — the agent cannot resolve trade-offs alone

## Uncertainty Declaration

All findings must declare what remains unknown or unverified:

```
[Action]: [finding] -- Unknown: [what remains unverified]
```

- `Unknown:` clause is **mandatory** for Investigate and Decide actions
- `Unknown:` clause is **recommended** for Fix and Plan actions
- Omitting uncertainty leads to false confidence and wasted effort

## Examples

```
Fix: Missing input validation on collection name field -- Unknown: none, root cause confirmed
Investigate: Intermittent 500 on batch export -- Unknown: whether it's memory or timeout related
Plan: Need rate limiting on AI compose endpoint -- Unknown: expected request volume at scale
Decide: Should tags be stored denormalized for read speed or normalized for consistency? -- Unknown: actual read/write ratio in production
```

## Integration with Other Skills

- `/agentflow-dod` requires FIPD classification on all quality findings
- `/agentflow-loop` cleanup sub-loop uses FIPD to decide fix vs. pause
- Known patterns in KNOWN_PATTERNS.md carry FIPD action tags

See [taxonomy.md](taxonomy.md) for extended examples and edge cases.
