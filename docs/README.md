# Shepherd / AgentFlow — Docs Site

Static HTML documentation and panel playgrounds for **Shepherd / AgentFlow** — the unified AI agent governance system that merges four frameworks (AgentFlow, Superpowers, SuperClaude, Ralph Loop) into a single product. This `docs/` subfolder hosts the published reference site, expert-panel demos (`spec-panel-playground.html`, `business-panel-playground.html`, `pipeline-playground.html`), and PDF exports of the methodology and governance analyses.

## At a Glance

| Property | Value |
|----------|-------|
| Stack | Static HTML |
| Status | Shipped (v1.0 live, actively evolving) |
| Repo | `20_agentflow/docs` |

## Contents

- `index.html` — landing page
- `shepherd.html` — Shepherd product overview
- `spec-panel-playground.html` — interactive Spec Panel demo (gate >= 7.0)
- `business-panel-playground.html` — Business Panel demo
- `pipeline-playground.html` — Scrumban pipeline visualization
- `governance-analysis-v1.0.pdf`, `po-methodology-v1.0.pdf` — methodology PDFs
- `specs/`, `plans/` — governance artifacts
- `ASSETS.md` — asset registry

## What Shepherd Provides

- **Scrumban Pipeline** — Inbox → Backlog (Ideation/Refining/Ready) → Queue (TODO-Today) → Done
- **14-Step Autopilot Loop** — quality-gated execution with DOR/DOD checkpoints (defined in `CLAUDE-LOOP.md`)
- **35 Installable Skills** — `/sh:*` commands for pipeline, implementation, analysis, expert panels
- **Expert Panels** — multi-expert review with scoring gates (Spec, Business, Architecture, Security, Design, Test, DevOps, Legal, Marketing, Content, Visualization, AI)
- **DOR / DOD Quality Gates** — non-negotiable entry/exit criteria

The full system also includes a Pipeline Dashboard, WinForms remote control, Tether cross-agent messaging, and the FIPD (Fix/Investigate/Plan/Decide) finding taxonomy.

---

Governed by `00_Governance/`. Published on GitHub.
