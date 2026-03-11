# DOR Checklist (Printable)

## Full DOR — Features & Enhancements

```
[ ] User Stories defined (As a... I want... So that...)
[ ] Acceptance Criteria written (testable, Given/When/Then)
[ ] Spec document exists (requirements doc)
[ ] Spec panel score >= 7.0
[ ] Architecture decided (design doc if new modules/APIs)
[ ] Dependencies identified (needs:/blocks: tags)
[ ] Test strategy known (types + approximate count)
[ ] No constraint violations (checked against CLAUDE.md)
[ ] Estimated size (S/M/L tagged in BACKLOG)
```

## Bug DOR-lite

```
[ ] Root cause identified (specific file/line/mechanism)
[ ] Fix plan (1-3 concrete steps; >3 = use full DOR)
[ ] Regression test named (test file + test case)
[ ] No constraint violations
[ ] Estimate (XS or S; larger = use full DOR)
```

## Size Definitions

| Size | Queue Items | DOR Level | Audit Level |
|------|------------|-----------|-------------|
| XS | 1 | Bug DOR-lite | Greenlight only |
| S | 1-3 | Full or Bug DOR-lite | Greenlight only |
| M | 4-8 | Full DOR | Greenlight + deep audit |
| L | 9+ | Full DOR | Greenlight + deep audit |
