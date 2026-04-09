# BACKLOG — Cross-Project

> **Central priority authority.** Items here span projects or are project-agnostic.
> Project-scoped items stay in their own BACKLOG.md.
>
> Items flow: **Ideation -> Refining -> Ready -> project TODO-Today.md (execution)**

---

## Ideation

> **Moved to Idea Forge** — items imported into Consigliere Idea Forge (`http://localhost:9104/ideas`) on 2026-04-09.

## Refining

## Ready

- **Code-Level Quality Gate Augmentation** → DONE (2026-03-09) `[governance]` `[quality]` · **S** _(project: Governance)_ — Adopt two high-leverage quality patterns from [ryanthedev/code-foundations](https://github.com/ryanthedev/code-foundations) (MIT, v4.0) to add code-level enforcement where DOR/DOD currently operate only at process level. Business panel (5/5 consensus) + spec-panel (pass 1: 2.9/10 → pass 2: 7.6/10) shaped scope.
  - **Source:** *Code Complete* assessment framework (Fix/Investigate/Plan/Decide taxonomy + uncertainty declaration)
  - **Excluded (business panel unanimous):** 614-check rubric, slash commands, model auto-selection, feature branch enforcement, debugging workflow
  - **Risk:** R-LOW — pure documentation change, no runtime dependency. KNOWN_PATTERNS.md is LLM-read only (no programmatic parser).
  - **Rollback:** If FIPD adoption causes friction after 2 sprints, revert to severity-only and log findings in retro.
  - **User Stories:**
    - **US-QG-01:** As a governance consumer, I want every finding classified by action type (Fix/Investigate/Plan/Decide) so that I know what to do next without re-analyzing the issue.
      - **AC-1:** Given KNOWN_PATTERNS.md, when I read any row, then it has an "Action" column with exactly one value from {Fix, Investigate, Plan, Decide}.
      - **AC-2:** Given a new finding from `/sc:analyze` or quality audit, when the finding is reported, then it is prefixed with its FIPD action type (FIPD *replaces* severity as the primary classifier; severity may remain as metadata but is not the leading label).
      - **AC-3:** Given DOD.md, when I read the quality audit enforcement step, then it references the FIPD taxonomy and links to the definitions.
      - **AC-4:** Given the 10 existing KNOWN_PATTERNS rows, when the migration is complete, then all 10 rows have been backfilled with the correct action classification.
      - **FIPD definitions:**
        - **Fix:** Root cause known, solution clear — implement immediately
        - **Investigate:** Symptom observed, root cause unknown — gather data before acting
        - **Plan:** Issue understood, solution *direction* is known but requires design work — add to backlog
        - **Decide:** Trade-off identified, multiple valid directions exist requiring human judgment — escalate to decision-maker
    - **US-QG-02:** As a reviewer, I want every analysis finding to declare what remains unknown or unverified so that I don't act on false confidence.
      - **AC-1:** Given KNOWN_PATTERNS.md, when I read the patterns list, then there is a meta-pattern row stating: "All review/analysis findings must declare what remains unknown or unverified."
      - **AC-2:** Given a finding output, when the action type is Investigate or Decide, then an `Unknown:` clause is mandatory.
      - **AC-3:** Given a finding output, when the action type is Fix or Plan, then an `Unknown:` clause is recommended but optional.
      - **AC-4:** Given an agent that reads the updated KNOWN_PATTERNS, when it classifies a new hypothetical finding, then it produces output matching the FIPD + uncertainty format. Pass criterion: output contains (a) one FIPD prefix, (b) `Unknown:` clause when action is Investigate or Decide, (c) valid sentence structure. No golden answer match required.
  - **Deliverables:** (1) KNOWN_PATTERNS.md schema change + backfill, (2) uncertainty meta-pattern row, (3) DOD.md finding format reference
  - **Test strategy:** Agent acceptance test — read updated KNOWN_PATTERNS, classify a novel finding, verify FIPD + uncertainty output format
  - **Dependencies:** None
  - **Before/After examples:**
    - KNOWN_PATTERNS row — Before: `| 2 | Catching bare Exception | Catch specific exceptions | SVG-PAINT |` → After: `| 2 | Catching bare Exception | Catch specific exceptions | SVG-PAINT | Fix |`
    - Finding output (Fix) — Before: `⚠️ MEDIUM: Unguarded setattr loop in config_service.py:45` → After: `Fix: Unguarded setattr loop in config_service.py:45 · Unknown: whether current PERSISTED_FIELDS whitelist covers all callers`
    - Finding output (Investigate) — `Investigate: Intermittent 500 on /api/collections endpoint · Unknown: whether caused by connection pool exhaustion or upstream timeout`
  - **Spec-panel:** pass 1: 2.9/10 → pass 2: **7.6/10** (gate passed)

- **PO Capabilities: 8 functions** (refining 2026-03-01) · **L** _(project: Governance)_
  - Spec: [requirements/REQ_PO_CAPABILITIES.md](requirements/REQ_PO_CAPABILITIES.md)
  - 8 capabilities: Prioritization, Critical Path, Dependencies, Backlog Review, Planning Rounds, Risk Calendar, Retros, Release Bundling
  - 15 User Stories (US-P-01/02, US-CP-01/02, US-D-01/02, US-BR-01/02, US-SPR-01/02/03, US-R-01/02, US-RT-01/02, US-RB-01/02)
  - 5 open questions: **all resolved** (see spec §Open Questions — Resolved)
  - Spec-panel pass 1: **6.4/10** → 16 improvements applied (precedence rule, Done def, RACI, flag severity, parsing grammar, validation, integrated example, cross-project deps, 150-line rule, planning interactive gates, retro quality bar)
  - **Missing before Ready:** `/sc:spec-panel` re-score >= 7.0, user sign-off on BACKLOG.md format changes
