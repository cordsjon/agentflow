# OpenSandbox Autonomous Dev Pipeline — Design Spec
**Date:** 2026-04-28
**Status:** Draft v3 — Plan 1 (Infrastructure Foundation) shipped 2026-04-28; spec updated with actuals
**Owner:** Jonas Cords

> **Plan 1 status (2026-04-28):** Complete and verified. Public health endpoint live at `https://paperclip.getaccess.cloud/pipeline/health` returning `{"opensandbox":"up","hermes":"down","paperclip":"up","active_jobs":0}`. See `~/projects/30_OpenSandboxPipeline/HANDOVER.md` for the deploy + verification trail. Webhook public ingress deferred to Plan 2.

---

## Summary

An autonomous software development pipeline that uses OpenSandbox (alibaba/OpenSandbox) as the isolated execution and context boundary for AI agent jobs. Paperclip orchestrates jobs, Agentflow/Shepherd governs execution inside each sandbox, and Hermes verifies output. Customers submit a brief via guided intake dialogue; the pipeline builds and delivers working software.

Three customer tiers: internal (yourself), business clients (managed, high-touch), developer self-serve (API access). Sequenced in that order to validate before scaling.

---

## Problem Statement

Running AI agent jobs for multiple customers on a shared Claude Code runtime creates context pollution — customer data, codebases, and system prompts bleed into your primary session. Additionally, untrusted or unfamiliar code generated for customers cannot safely execute on the host machine.

OpenSandbox solves both: each job runs in an isolated container with its own Claude Code process, injected context, and network controls. Your primary runtime never sees customer data. Failed or misbehaving code is contained.

---

## Current State vs. Required State

**Paperclip today:** Early-stage orchestrator. Supports issue creation, task listing, and basic routing via Paperclip skill. No async job state machine, no lifecycle API integration, no `skill_debt/pending.jsonl` tracking.

**Paperclip required (Phase 1):** Async job state tracking (INTAKE → DONE state machine), OpenSandbox lifecycle API calls, gap-analysis output ingestion. This is the largest gap — Paperclip needs a state machine extension before the pipeline can run.

**Hermes today:** CLI test tool (`hermes_test.py`) targeting a live Android app at `getaccess.cloud/hermes`. Supports api/chat/screenshot/logcat. Not wired to any pipeline.

**Hermes required (Phase 1):** External verification trigger called by `hermes-verify` skill after sandbox completion signal. Must accept a sandbox port/URL target rather than a hardcoded host, and return structured pass/fail JSON.

**Agentflow/Shepherd today:** Full governance loop with 14 steps, skills, quality gates. Runs in interactive Claude Code sessions.

**Agentflow/Shepherd required (Phase 1):** Skills must run inside a headless sandbox (no interactive terminal). The autopilot loop must self-terminate and write a completion marker when the US is done.

---

## Architecture

```
CUSTOMER INTAKE
  └─ Guided clarifying dialogue (human-conducted, Tier 3; API payload, Tier 2)
  └─ Output: structured brief JSON (schema below)
        │
        ▼
PAPERCLIP (Orchestrator)
  └─ Receives approved brief
  └─ Decomposes into User Stories via Agentflow DOR checklist
  └─ Manages async job state machine (INTAKE → DONE)
  └─ Tracks skill_debt/pending.jsonl from gap-analysis outputs
        │
        ▼
OPENSANDBOX (Execution + Context Boundary)
  ┌─────────────────────────────────────────┐
  │  Per-job container                       │
  │  - Fresh Claude Code instance            │
  │  - Injected CLAUDE.md (3-layer merge)    │
  │  - Injected scaffolding / codebase       │
  │  - Agentflow skills injected as files    │
  │  - Network: approved FQDNs only          │
  │  - Resource limits: 2 CPU, 4GB RAM       │
  │  - TTL: 2h hard timeout, 30min idle kill │
  └─────────────────────────────────────────┘
        │  completion signal: POST /webhook or
        │  file marker: /workspace/.done
        ▼
HERMES (Verification)
  └─ Fires against sandbox exposed port on completion signal
  └─ ADB for Android, curl/pytest for web/API
  └─ Pass threshold: web/API ≥ 90% endpoints green; Android ≥ 1 screenshot + logcat clean
  └─ Pass → extract artifact / Fail → gap-analysis → Paperclip retry
        │
        ▼
DELIVERY
  └─ Artifact extracted (APK, zip, deployed URL)
  └─ Customer notified via Paperclip dashboard + email
  └─ gap-analysis report attached
```

---

## Brief JSON Schema

Nothing enters the queue without a complete brief matching this schema:

```json
{
  "id": "job-042",
  "goal": "Build a calorie tracking Flutter app with daily log and weekly chart",
  "stack": "flutter",
  "constraints": ["offline-first", "no third-party analytics"],
  "acceptance_criteria": [
    "User can log a meal with name + kcal",
    "Daily total is visible on home screen",
    "Weekly bar chart renders without network"
  ],
  "open_questions_resolved": [
    {"q": "iOS or Android only?", "a": "Android only, API level 26+"}
  ],
  "tier": "business",
  "customer_id": "cust-007"
}
```

Validation: `stack` must be one of `[flutter, fastapi, vanilla-js, python-cli, mixed]`. `acceptance_criteria` must have ≥ 1 entry. `open_questions_resolved` must be non-empty (no unresolved questions enter the queue).

---

## Job Lifecycle

```
INTAKE → SPECCED → QUEUED → RUNNING → VERIFYING → DONE
                                │                   │
                                └── FAILED ─────────┘
                                      │
                                   RETRY (max 3, new sandbox each time)
                                      │
                                   HUMAN_REVIEW
```

**Intake → Specced:** Guided dialogue resolves open questions. Brief JSON validated against schema. Nothing enters queue without complete brief.

**Specced → Queued:** Paperclip decomposes brief into User Stories. Each US gets its own job entry with dependency mapping. ETA estimate returned to customer immediately.

**Queued → Running:** Paperclip calls OpenSandbox lifecycle API (circuit-breaker: 3 retries with 5s backoff before marking job FAILED). `context-pack` skill builds the CLAUDE.md. Sandbox starts with Claude Code running Agentflow autopilot loop headlessly.

**Running → Verifying:** Completion signal received (POST to Paperclip webhook from inside sandbox, or `polling: /workspace/.done` every 30s as fallback). Hermes fires against sandbox's exposed port. TTL timeout (2h) triggers force-kill + FAILED state.

**Verifying → Done / Failed:**
- Pass: artifact extracted via `execd` file API, sandbox destroyed, customer notified.
- Fail: `gap-analysis` runs (skill gap or code bug?), error + logs packaged, retry counter incremented. Each retry uses a **new sandbox** (prior sandbox state is discarded). `gap-analysis` runs before each retry, not just after the third.
- After 3 retries: `HUMAN_REVIEW` — Paperclip sends push notification (details below).

---

## Completion Signal Contract

Claude Code running inside the sandbox signals completion by **both**:

1. Writing `/workspace/.done` with content `{"status": "complete", "artifact": "<path>", "job_id": "<id>"}`
2. POSTing to `http://host.docker.internal:9090/jobs/<id>/complete` (Paperclip webhook port)

Hermes polls `/workspace/.done` every 30s as fallback if webhook delivery fails. If neither signal arrives within TTL (2h), Paperclip marks the job FAILED with reason `timeout`.

Agentflow autopilot loop must be extended with a **termination hook**: after `DONE-Today.md` is updated and all USs complete, write the `.done` marker and POST the webhook. This is the primary change needed to Agentflow for headless operation.

---

## Context Engineering

The per-job `CLAUDE.md` is constructed in three layers, merged in order (later layers override earlier):

1. **Base layer** — `~/.claude/CLAUDE.md` copied in at sandbox start. Injects global tenets, coding standards, communication rules.
2. **Customer layer** — Generated from brief JSON. Injects: project goal, stack constraints, acceptance criteria, delivery format, customer-specific conventions. Customer layer may NOT override safety tenets (no bare `except`, atomic writes, etc.) — these are locked in base layer.
3. **Stack layer** — Generated by `scaffold-init` skill. Injects stack-specific patterns (FastAPI conventions, Flutter project structure, etc.).

**Layer conflict rule:** Customer layer may extend but not contradict base layer tenets. If a customer brief requests a pattern that conflicts with a base tenet (e.g., "use bare except for simplicity"), the customer layer silently drops that instruction and logs a gap-analysis entry.

**Skills mounting:** Agentflow skills are injected as files into `/workspace/.claude/skills/` at sandbox start via OpenSandbox's `execd` file write API. Skills are read-only inside the sandbox (permissions: 444).

---

## Gap Analysis Loop

`gap-analysis` is a **loop invariant**, not a one-shot assessment. It runs at:

- **US completion** — did this US reveal an uncovered skill pattern?
- **Hermes fail** — is this a skill gap or a code bug? (runs before each retry)
- **Customer engagement end** — recurring patterns across this job?
- **`/kaizen` retro** — promote accumulated gaps to skill backlog (every 10 stories)

Output format mirrors the existing `analyze-debt` pattern:
```json
{"date": "YYYY-MM-DD", "gap": "no skill for APK signing in CI", "trigger": "hermes-fail:job-042", "priority": "high", "recurrence": 1}
```
Written to `skill_debt/pending.jsonl`. `recurrence` increments each time the same gap fires — high-recurrence gaps are auto-promoted to Sprint backlog without waiting for retro.

---

## Pipeline Test Strategy

The pipeline components themselves require a test strategy distinct from the output they verify:

| Component | Test method | Pass criteria |
|---|---|---|
| `context-pack` | Unit: given brief JSON, assert generated CLAUDE.md contains all 3 layers with no base-tenet overrides | 100% layer presence, 0 tenet conflicts |
| `sandbox-lifecycle` | Integration: create sandbox, write file, read it back, destroy. Assert TTL kills idle sandbox | File round-trip < 5s, TTL kill within 60s of deadline |
| `hermes-verify` | Integration: point at a known-good fixture server, assert pass result. Point at known-bad, assert fail + gap-analysis entry | Both cases classified correctly |
| `gap-analysis` | Unit: given a structured error log, assert gap entry written with correct trigger + priority | Entry matches expected schema |
| Full pipeline | E2E on own project: run one real US through INTAKE → DONE on a known project. Assert artifact exists and Hermes passes | US completes within 30min, 0 HUMAN_REVIEW |

Phase 1 success gate: **≥ 4 of 5 E2E runs complete without HUMAN_REVIEW** across 2+ own projects. Measured via Paperclip job log.

---

## HUMAN_REVIEW Notification

Paperclip has no native webhook or notification API. Notification is handled via a Claude Code `PostToolUse` hook:

- Hook watches for Write tool calls targeting `HUMAN_REVIEW.md`
- On match: fires `osascript -e 'display notification "Job requires review" with title "HUMAN_REVIEW"'`
- macOS system notification appears immediately; no Paperclip API changes needed

**Structured failure summary** written to `~/projects/00_portmgr/HUMAN_REVIEW.md`:

```markdown
## job-042 — HUMAN_REVIEW (2026-04-28 14:32)
**Brief:** Flutter calorie tracker
**Failed after:** 3 retries
**Last error:** hermes-fail: screenshot black screen, logcat: NullPointerException in MainActivity
**Gap entries:** [no skill for Android permission handling at runtime]
**Artifact location:** /tmp/jobs/job-042/workspace.tar.gz (preserved)
**Action required:** Review gap, add skill or fix brief, re-queue manually
```

Artifact is preserved (not destroyed) on `HUMAN_REVIEW` to allow manual inspection.

---

## Skill Inventory

### Existing skills — transfer cleanly (run inside sandbox unchanged)
- `brainstorm`, `spec-panel`, `test-driven-development`, `commit-smart`, `finishing-branch`, `session-handoff`, `requirements-clarity`, `sc:analyze`, `sc:cleanup`, `production-code-audit`

### Partial transfers (need extension)
| Skill | Gap | Fix |
|---|---|---|
| `verification-before-completion` | Assumes local test execution | Extend to accept external Hermes result as verification evidence |
| `sc:workflow` | Single-repo session assumption | Add multi-job awareness for Paperclip-managed queues |
| Agentflow autopilot loop | No termination hook for headless operation | Add `.done` marker write + webhook POST at loop completion |

### New skills — MVP (Phase 1)
| Priority | Skill | Purpose |
|---|---|---|
| 1 | `gap-analysis` | Loop invariant — detects missing skills after every US and every Hermes fail |
| 2 | `context-pack` | Constructs per-job CLAUDE.md from base + customer + stack layers with conflict resolution |
| 3 | `sandbox-lifecycle` | Wraps OpenSandbox API: create → inject → monitor → extract → destroy; circuit-breaker included |
| 4 | `hermes-verify` | Fires Hermes against sandbox port, interprets results, feeds pass/fail + gap entry to Paperclip |

### New skills — Sprint 2
- `customer-intake` — customer-facing guided dialogue, outputs brief JSON matching schema
- `scaffold-init` — detects target stack from brief, generates initial project structure + stack CLAUDE.md layer

### New skills — Sprint 3+
- `job-escalate` — packages HUMAN_REVIEW notification with failure context
- `artifact-package` — stack-specific artifact extraction (APK, zip, deploy)

---

## Customer Tiers

| Tier | Interface | Intake | Pricing | Phase |
|---|---|---|---|---|
| Internal (you) | Claude Code CLI, direct Paperclip | None — push directly to queue | n/a | Now |
| Business client | You conduct guided dialogue | Human-in-the-loop, you resolve open questions | Project retainer / per-deliverable | Phase 2 |
| Developer self-serve | API + CLI | Structured brief via API payload | Per-job flat fee + per sandbox-hour for long-running jobs | Phase 3 |

---

## Delivery Model

All tiers use async delivery. No customer watches the pipeline in real time.

```
Brief submitted → ETA returned immediately
Pipeline runs (minutes to hours, capped at 2h TTL)
  ├── Pass → artifact + gap-analysis report delivered
  └── HUMAN_REVIEW → customer gets "in review" status, you notified via HUMAN_REVIEW.md + push
```

---

## Rollout Sequence

**Phase 1 — Internal validation**
Deploy OpenSandbox (Docker, Mac Mini M4, no Kubernetes). Build Paperclip state machine extension. Wire `gap-analysis` + `context-pack` + `sandbox-lifecycle` + `hermes-verify` into Agentflow. Run 5 real features across 2-3 own projects. Success gate: ≥ 4/5 E2E runs without HUMAN_REVIEW.

**Phase 2 — Tier 3 (business clients)**
Onboard 2-3 clients manually. You conduct intake, you review every escalation. Validates pricing and pipeline robustness on unknown stacks. gVisor security backend enabled at first external customer job.

**Phase 3 — Tier 2 (developer self-serve)**
Expose API. Build `customer-intake` skill + minimal intake form. Only when Tier 3 gap-analysis loop has stabilized skill inventory (defined as: <1 new high-priority gap per 10 jobs).

---

## Infrastructure

- **Runtime:** OpenSandbox on Docker (Mac Mini M4), single-tenant dev mode initially
- **Sandbox resource limits:** 2 vCPU, 4GB RAM, 10GB disk per job
- **Sandbox TTL:** 2h hard timeout, 30min idle kill (no filesystem writes for 30min)
- **Sandbox security backend:** runc (Phase 1) → gVisor (Phase 2, first external customer, trigger: Tier 3 onboarding)
- **Network:** per-sandbox FQDN egress control (OSEP-0001). OpenSandbox lifecycle API on Mac Mini:9124 (portmgr-allocated; 8080=Dagu, 8088=Rancher Desktop lima). Reverse `autossh` tunnel forwards VPS:9124→Mac:9124 (loopback only) for VPS-side liveness probes, and VPS:9090→Mac:9090 reserved for the future webhook listener. Public Paperclip webhook ingress is **deferred to Plan 2** — likely a new NPM proxy host on `webhook.getaccess.cloud` over 443 (port 9090 is firewalled and would require a stream proxy or ufw rule).
- **Kubernetes:** deferred until Phase 3 volume justifies ops overhead
- **MCP integration:** OpenSandbox MCP server exposes lifecycle as tool calls to Paperclip
- **Circuit breaker:** OpenSandbox API calls use 3-retry / 5s-backoff pattern; persistent failure → job FAILED, not silent hang

## Observability

### Job-level metrics
All job state transitions appended to `~/projects/00_portmgr/job-log.jsonl`:
```json
{"job_id": "job-042", "event": "RUNNING→VERIFYING", "ts": "2026-04-28T14:32:00Z", "duration_s": 847, "retry": 0, "gap_count": 0}
```
Fields: `job_id`, `event`, `ts`, `duration_s` (cumulative), `retry` (0-3), `gap_count`. Phase 1 success gate (≥4/5 without HUMAN_REVIEW) measured from this file.

### Pipeline health check
FastAPI endpoint on VPS: `GET https://paperclip.getaccess.cloud/pipeline/health` (apex `getaccess.cloud` TLS routing is broken pre-Plan-1 — no NPM proxy host for the apex; the `paperclip` subdomain is what's actually live).
Returns:
```json
{"opensandbox": "up", "hermes": "up", "paperclip": "up", "active_jobs": 2}
```
Internally: uvicorn on VPS:9091 → systemd unit `pipeline-health.service` → probes Mac Mini OpenSandbox via the autossh reverse tunnel. Public exposure routed through NPM custom location on proxy host `paperclip.getaccess.cloud` (id 18) with `rewrite ^/pipeline/health$ /health break;`.

`PostToolUse` hook runs health check on session start. `osascript` alert if any component is `down`.

### Customer job status API
`GET https://getaccess.cloud/jobs/{job_id}/status` — returns current state, ETA, and download link on completion. Used by Tier 2/3 customers to poll progress. No auth required for Phase 2 (security by obscure job ID); add API key for Phase 3.

### Artifact delivery
On job completion: artifacts extracted from sandbox `/workspace/artifacts/` → copied to VPS at `getaccess.cloud/artifacts/{job_id}/`. Time-limited download link (48h expiry) included in customer notification. Artifacts deleted after 7 days.

---

## Resolved Decisions

1. **Completion signal:** Dual mechanism — webhook POST + `.done` file polling fallback (§Completion Signal Contract)
2. **Retry strategy:** New sandbox per retry; gap-analysis runs before each retry (§Job Lifecycle)
3. **gVisor trigger:** First Tier 3 external customer job (§Rollout Sequence)
4. **HUMAN_REVIEW notification:** `PostToolUse` hook watches Write tool calls to `HUMAN_REVIEW.md` → fires `osascript` macOS notification. Paperclip has no native notification API. (§HUMAN_REVIEW Notification)
5. **Tier 2 pricing:** Per-job flat fee + per-sandbox-hour for long-running jobs. Short jobs pay flat; complex multi-hour jobs pay time-based on top. Prevents underpricing large briefs while keeping simple jobs predictably priced.
6. **VPS public routing (Plan 1):** Public nginx is **NPM (Nginx Proxy Manager)** in container `npm`, host network mode — not host nginx (which is a decoy). All external routes are managed via NPM REST API on `127.0.0.1:81/api/`, not by editing `/etc/nginx/*` or tinycp configs. Custom locations on existing proxy hosts use `advanced_config` for path rewrites since NPM renders `proxy_pass` without a URI. (Verified 2026-04-28 via `docker top npm` + `cat /proc/<master>/cgroup`.)
7. **OpenSandbox local port (Plan 1):** Mac Mini:9124 (portmgr-allocated). 8080 is owned by Dagu; 8088 is taken by Rancher Desktop's lima ssh mux. Port chosen for stability across local services.