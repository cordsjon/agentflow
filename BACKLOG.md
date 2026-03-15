# BACKLOG — Cross-Project

> **Central priority authority.** Items here span projects or are project-agnostic.
> Project-scoped items stay in their own BACKLOG.md.
>
> Items flow: **Ideation -> Refining -> Ready -> project TODO-Today.md (execution)**

---

## Ideation

- **Governance Repo: Tether-as-PO-Agent** — Evolve governance from passive files to an active agent. The governance repo becomes a "PO agent" that sends prioritized work to project-scoped agents (Claude, Gemini, ChatGPT) via Tether. Priority changes propagate in real-time. Retro insights flow back via Tether messages. Requires: Tether thread per project, governance CLI that reads BACKLOG priority order and posts to Tether.

- **WinForms UI for Tether** _(project: Tether)_ — Desktop dashboard to see what's sent, what came back, log errors. Visual monitor for the postoffice: message list with status (pending/completed/failed), sender/recipient filters, error log viewer, real-time refresh. Wraps existing HTTP API (localhost:7890) as data source.

- **LLM Scrum Masters** (ideation 2026-03-01) `[process]` — Employ external LLMs (Gemini, ChatGPT) as independent scrum masters / retro facilitators. They receive retro data via Tether, run their own analysis, and post improvement suggestions back. Provides an outside perspective that Claude (as primary executor) may be blind to. Requires: Tether cross-agent messaging, structured retro data format, prompt templates for each LLM.

- **Project Reporting Component** (ideation 2026-03-01) `[governance]` — Governance Hub needs visibility into project activity. Report per project: what changed in what period (commits, stories completed, files touched), what is expected to change (queued items, critical path forecast, upcoming risks). Aggregated cross-project view for the PO. Output destinations: markdown summary in `reports/`, Excel dashboard (existing sync mechanism), Google Sheets (existing Tether bridge). Could feed into planning rounds (§5) as input data.

- **Daily Auto-Commit for Governance** (ideation 2026-03-01) `[infrastructure]` — Scheduled task (Windows Task Scheduler or Startup script) that runs once daily: stages all changed governance files (BACKLOG.md, decision_log.md, MEMORY.md, knowledge/, retros/), commits with message `"daily: governance snapshot YYYY-MM-DD"`, and triggers sync-repos.ps1. Prevents loss of planning work between sessions. Guard: only commits if there are actual changes (no empty commits). Does NOT push to remote — local safety net only. Could extend to all governed project repos with the same pattern.

- **Governance Dashboard — WinForms Widget** (ideation 2026-03-01) `[governance]` `[winforms]` — Purpose-built desktop widget for the PO to monitor and interact with the governance loop. NOT a build pipeline remote control — this is a planning and priority cockpit. See detailed concept below.
  - **Data source:** Reads governance markdown files directly (BACKLOG.md, TODO-Today.md per project, ROADMAP.md, decision_log.md, retros/counter.json, knowledge/_index.md) + git log for activity
  - **Panels:**
    - **Backlog Health** — Ideation/Refining/Ready item counts per project, staleness badges (green/amber/red), date annotations visualized as age bars
    - **Critical Path** — Visual dependency chain, current position indicator, blocked/done status per item, optical barrier between locked and free zones
    - **Risk Heatmap** — L/M/H grid colored by likelihood x impact, items mapped to risk cells, closed risks greyed out
    - **Queue Monitor** — Per-project TODO-Today progress bars (checked/total), current autopilot status (run/pause/stop), last `.claude-action` message as ticker
    - **Planning Triggers** — Live indicator lights: queue near-empty? 5+ Ready idle? path changed? retro due? Each light links to "Start planning round" action
    - **Decision Inbox** — Unresolved INFO/WARN flags from all projects, one-click "Decide" button that logs to decision_log.md
    - **Retro Counter** — Per-project story count toward next retro, progress ring visualization
    - **Domain Knowledge** — Domain spoke list with item counts, staleness, last-updated dates, interlink map
  - **Actions (not read-only):**
    - Re-number Ready items (drag-and-drop priority)
    - Add/remove critical path items
    - Log decisions (clears flags)
    - Trigger planning round / retro
    - Initiate sync (runs sync-repos.ps1)
  - **Tech:** WinForms (.NET), reads .md files via regex parsing, writes back via file I/O, no server needed (local-first). Could optionally poll Tether HTTP API for cross-agent status
  - **Figma:** Wireframe needed — see below

- **AG-BOS: Brand Context Layer + Per-Skill Learnings + Skill Overlap Detection** (ideation 2026-03-15) `[agentflow]` `[skills]` — Extend agentflow with three features inspired by "Agentic OS" pattern (video analysis 2026-03-15). All three integrate into the existing governance loop — no separate system needed.
  - **1. Brand context as first-class folder** — `brand-context/` directory per governed project containing: `voice.md` (tone, vocabulary, do/don't), `icp.md` (ideal customer profile), `positioning.md` (market angle, differentiators), `samples/` (gold-standard outputs), `assets.md` (links, handles, visual refs). Foundation skills interview the user once and generate structured files. All execution skills read from this folder. For SVG-PAINT: Etsy buyer persona, listing voice, competitor positioning.
  - **2. Per-skill learnings** — Each skill gets a `learnings:` section (or companion `learnings.md`) that captures user feedback specific to that skill's output. On skill execution, learnings are read before the skill runs. On session wrap-up, feedback is logged per skill. Complements the global KNOWN_PATTERNS / retro loop with skill-scoped memory. Lifecycle: feedback → learnings entry → skill.md update (if pattern is stable across 3+ entries).
  - **3. Skill overlap detection** — Before creating a new skill, scan all installed skills' front matter (triggers, strengths, tools used). Flag overlaps > 60% keyword match. Suggest merge, dependency, or scope narrowing. Prevents skill sprawl and routing ambiguity in ORCHESTRATOR.md.
  - **Dependencies:** None (pure additive to existing agentflow structure)
  - **Risk:** R-LOW — markdown files only, no runtime code. Main risk is over-engineering the brand context interview.
  - **Next:** Draft user stories for each sub-feature, spec-panel review

- **CogniShield — Personal AI Usage Proxy & Cognitive Atrophy Tracker** (ideation 2026-03-08) `[new-product]` — Local proxy that intercepts all personal AI usage (ChatGPT, Claude, Gemini etc.), categorizes delegated tasks (definitions, code, writing, reasoning, research), and prescribes mitigating offline exercises to counteract cognitive atrophy. Not anti-AI — pro-human. Context: MIT EEG study shows 83% recall failure minutes after ChatGPT use, 47% brain connectivity collapse, Wharton confirms "cognitive surrender" across 10K trials. Tech: mitmproxy + SQLite + exercise engine, CLI-first, privacy-first (no cloud). Features: delegation frequency tracking, counter-exercise prescriptions ("10 definitions delegated → look up 10 in a dictionary"), weekly cognitive health dashboard, optional spaced repetition. Separate project. `BV: R=M U=H S=H`
  - Next: market validation, proxy architecture spike, exercise taxonomy design

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
