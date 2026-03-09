# Definition of Ready (DOR)

**Gate:** Must pass BEFORE implementation begins.
An item that fails DOR cannot enter a project's TODO-Today queue. It stays in BACKLOG.md#Refining.

## Full DOR Checklist

- [ ] **User Stories defined** — at least 1 US with "As a [role], I want [goal], so that [benefit]"
- [ ] **Acceptance Criteria written** — each US has explicit, testable AC (Given/When/Then or bullet list)
- [ ] **Spec document exists** — requirements doc with functional requirements
- [ ] **Spec panel score >= 7.0** — `/sc:spec-panel` critique passed (or issues addressed and re-scored)
- [ ] **Architecture decided** — if new modules/APIs: design doc exists
- [ ] **Dependencies identified** — any blocking work listed and either complete or explicitly deferred
- [ ] **Test strategy known** — which test types needed (unit, integration, E2E), approximate count
- [ ] **No constraint violations** — feature doesn't conflict with project's CLAUDE.md constraints
- [ ] **Estimated size** — S (1-3 queue items), M (4-8), L (9+) — tagged in BACKLOG.md

## Bug DOR-lite

Lightweight gate for `[bug]` or `[hotfix]` items. No US template, no spec-panel score required.

- [ ] **Root cause identified** — specific file/line/mechanism documented
- [ ] **Fix plan** — 1-3 concrete steps; if > 3 steps it's a feature, use full DOR
- [ ] **Regression test named** — which test file + test case will catch this
- [ ] **No constraint violations** — fix doesn't conflict with project constraints
- [ ] **Estimate** — XS (1 item) or S (2 items); larger = use full DOR

## Hotfix Fast-Track

If a bug is **actively blocking development** (server down, build broken, data corruption):

1. Add bullet to INBOX.md immediately
2. `/triage` classifies as `[hotfix]`, moves directly to TODO-Today.md (skips Ideation/Refining)
3. Bug DOR-lite satisfied at triage time
4. Autopilot executes as next queue item

## Enforcement

```
/sc:spec-panel requirements/[spec].md --mode critique --focus requirements
Gate: Score >= 7.0 + all checklist items -> graduate to Ready
Any item missing or score < 7.0 -> stay in Refining, iterate
```

`/sc:workflow` MUST NOT generate a queue for an item that hasn't passed DOR.
