# FIPD Taxonomy — Extended Reference

## Decision Tree

```
Is the root cause known?
├── YES: Is the solution clear?
│   ├── YES -> FIX
│   └── NO (needs design) -> PLAN
└── NO: Are there multiple valid directions?
    ├── YES (trade-off) -> DECIDE
    └── NO (need more data) -> INVESTIGATE
```

## Detailed Examples by Category

### Fix Examples
```
Fix: Missing null check on collection.name causes AttributeError on line 42
  -- Unknown: none, reproduced and root cause confirmed

Fix: CSS z-index on modal is 10, should be 1000 to overlay header
  -- Unknown: none

Fix: Import order causes circular dependency between service_a and service_b
  -- Unknown: whether other modules have similar circular imports
```

### Investigate Examples
```
Investigate: Export fails intermittently with timeout after ~30 seconds
  -- Unknown: whether this is memory pressure, network, or CPU-bound

Investigate: Font rendering differs between Chrome and Firefox
  -- Unknown: which CSS property causes the divergence

Investigate: Test suite 2x slower since last merge
  -- Unknown: which specific test(s) regressed
```

### Plan Examples
```
Plan: Need pagination on glyph grid — currently loads all items
  -- Unknown: expected maximum item count per collection

Plan: Should extract color palette logic into shared utility
  -- Unknown: how many callers exist across the codebase

Plan: Database migration needed for new taxonomy fields
  -- Unknown: migration timing relative to other schema changes
```

### Decide Examples
```
Decide: Store computed SVG paths in DB (fast reads) or generate on-demand (less storage)?
  -- Unknown: actual read/write ratio in production

Decide: Use WebSocket for real-time updates or polling with 5s interval?
  -- Unknown: expected concurrent user count

Decide: Monorepo vs separate repos for frontend and backend?
  -- Unknown: team growth plans and deployment constraints
```

## Anti-Patterns

| Bad Practice | Why It's Wrong | Correct Approach |
|-------------|---------------|-----------------|
| Severity-only ("High/Medium/Low") | Tells you urgency but not action | Use FIPD — tells you what to DO |
| "Fix" without root cause | Premature, may fix symptom not cause | If root cause unknown, it's "Investigate" |
| "Investigate" without timebox | Can spiral indefinitely | Max 1 hour, then escalate or reclassify |
| Omitting Unknown clause | Creates false confidence | Always declare what's unverified |
| "Decide" without options listed | Unhelpful escalation | Present the trade-off with pros/cons |

## Integration Points

- **DOD Gate:** All quality findings must carry FIPD classification
- **Cleanup Sub-Loop:** Fix items are auto-resolved; Investigate/Plan/Decide pause the loop
- **KNOWN_PATTERNS.md:** Every entry has an Action column using FIPD
- **BACKLOG:** Plan items graduate to Ideation; Decide items surface immediately
