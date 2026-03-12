```
  ┌──────────────────────────────────────────────────────────────┐
  │                                                              │
  │        __                                                    │
  │       /  \   O        /)/)  /)/)  /)/)  /)/)  /)/)           │
  │      /----\ /|\╭╮    ( ..) ( ..) ( ..) ( ..) ( ..)           │
  │             / \││    INBOX IDEA  SPEC  QUEUE DONE            │
  │               ╰╯       ·─────→─────→─────→─────→ ✓           │
  │                                                              │
  │               S H E P H E R D  /  agentflow                  │
  │         Unified AI agent governance framework                │
  │                                                              │
  └──────────────────────────────────────────────────────────────┘
```

**Unified AI agent governance — pipeline, skills, expert panels, and persistence in one framework.**

Shepherd merges four systems into a single product:

- **AgentFlow's** Scrumban pipeline and 14-step quality-gated loop
- **Superpowers'** execution skills (TDD, verification, code review, debugging)
- **SuperClaude's** analysis skills and extensible expert panels
- **Ralph Loop's** stop-hook persistence for session survival

One install. One namespace (`/sh:`). 34 commands. Zero duplicates.

Built for software development with coding agents (Claude Code, Cursor, Codex, Devin, etc.), but the loop, pipeline, and quality gates are domain-agnostic. Any work that is **large enough to need a backlog, repetitive enough to benefit from automation, or complex enough to require quality checkpoints** fits the model.

### Beyond code — real-world examples

| Domain | What the loop governs |
|--------|-----------------------|
| **Software development** | Feature implementation, TDD cycles, PR review, deployment |
| **Data visualization** | Programmatic poster/infographic generation — iterating layouts, data transforms, and print-ready export across dozens of revision cycles |
| **Document production** | Large technical specs, compliance reports, or multi-chapter manuals — drafting, review gates, version control |
| **Data pipelines** | ETL jobs, dataset curation, validation passes — each stage quality-gated before the next |
| **Content campaigns** | Blog series, social assets, email sequences — editorial calendar as backlog, brand guidelines as quality gate |
| **Research & analysis** | Literature reviews, competitive intelligence, market sizing — structured evidence collection with review checkpoints |
| **Asset generation** | SVG libraries, icon sets, print templates — batch creation with contrast/accessibility checks before export |
| **Spreadsheet engineering** | Programmatic Excel/Sheets builds — formula audits, data validation, visual QA before distribution |

The pattern is always the same: **inbox → backlog → prioritized queue → bounded execution loop → quality gate → done.** The skills and gates change per domain, but the pipeline doesn't.

---

## What is this?

Most AI agents run in one of two modes: fully manual (you prompt every step) or fully autonomous (YOLO). **Shepherd** provides the middle ground — a Scrumban pipeline where:

- **Agents execute autonomously** within a bounded loop (pick task, execute, verify, commit)
- **Quality gates halt execution** when issues exceed thresholds (no silent failures)
- **Humans control the queue** (what gets built, in what order, with what priority)
- **Skills plug into loop stages** (review, validation, audit — each wired to a specific step)

```
INBOX → BACKLOG (Ideation → Refining → Ready) → TODO-Today → DONE-Today
                                                      ↑
                                               Autopilot Loop
                                          (14 steps, quality-gated)
```

## Core Components

| File | Purpose |
|------|---------|
| [CLAUDE-LOOP.md](CLAUDE-LOOP.md) | The execution loop — 3 nested loops, 14 inner steps, semaphore control |
| [GOVERNANCE-GUIDE.md](GOVERNANCE-GUIDE.md) | Full framework reference — pipeline, quality gates, skill portfolios |
| [DOD.md](DOD.md) | Definition of Done — quality gate before deployment |
| [DOR.md](DOR.md) | Definition of Ready — entry criteria before implementation |
| [ORCHESTRATOR.md](ORCHESTRATOR.md) | Task routing, agent assignment, stall detection |
| [AGENT_CAPABILITIES.md](AGENT_CAPABILITIES.md) | Agent capability matrix for task routing |
| [KNOWN_PATTERNS.md](KNOWN_PATTERNS.md) | Anti-pattern catalog — consult before writing code |
| [SKILLS.md](SKILLS.md) | Complete skill catalog — dependencies, chains, examples, portfolios |
| [experts/](experts/) | Extensible expert registry — panels, packs, individual expert files |
| [ORIGIN.md](ORIGIN.md) | The genesis story — how four systems became one |
| [docs/specs/](docs/specs/) | Design specifications and architecture documents |
| [docs/ASSETS.md](docs/ASSETS.md) | Published PDF reference documents with versioning |

## The Loop (simplified)

```
1. Check semaphore (run/pause)
2. Load context from previous iteration
3. Read first unchecked task from queue
4. Route: assign agent, check deps, preload context
5. Verify task meets Definition of Ready
6. Execute (TDD-first for user stories)
7. Verify acceptance criteria with evidence
8. Self-review changed files
9. Cleanup sub-loop (fix all Low findings)
10. Commit (atomic, conventional)
11. PR + branch cleanup (if feature branch)
12. Move to done, cascade unblocked deps
13. Save context for next session
14. Next task or stop
```

**Key invariant:** Medium+ severity findings pause the loop — the agent stops and asks for human review. No silent quality degradation.

## Quality Gate Stack

```
┌─────────────────────┐
│  GREENLIGHT          │  Project test suite — 100% green
├─────────────────────┤
│  DEEP AUDIT          │  Security/perf/arch scan (M+ tasks)
├─────────────────────┤
│  DEFINITION OF DONE  │  Code quality + architecture + committed + deployable
└─────────────────────┘
```

## Skill Integration

All 34 skills use the `/sh:` namespace and plug into specific loop stages:

| Loop Stage | Shepherd Skills |
|------------|----------------|
| Execute | `/sh:tdd`, `/sh:execute` |
| Verify | `/sh:verify` |
| Review | `/sh:review` |
| Cleanup | `/sh:analyze` (FIPD taxonomy) |
| Commit | `/sh:dod` |
| Branch | `/sh:finish` |
| Context | `/sh:handoff` |
| Retro | `/sh:retro` |

Plus on-demand skills: `/sh:debug`, `/sh:research`, `/sh:explain`, `/sh:estimate`, `/sh:test`, `/sh:document`, `/sh:troubleshoot`, `/sh:index-repo`, `/sh:select-tool`, `/sh:parallel`, `/sh:worktree`, `/sh:plan`.

And expert panels: `/sh:spec-panel` (scoring gate ≥ 7.0), `/sh:business-panel` (advisory).
## Getting Started

1. **Copy these files** into your project's `governance/` directory
2. **Reference from your CLAUDE.md** (or equivalent agent instructions):
   ```markdown
   ## Governance
   This project follows the Shepherd loop.
   See governance/CLAUDE-LOOP.md for execution model.
   ```
3. **Create your pipeline files:**
   - `INBOX.md` — raw input dump
   - `BACKLOG.md` — with `## Ideation`, `## Refining`, `## Ready` sections
   - `TODO-Today.md` — with `## Queue` section
   - `DONE-Today.md` — completion log
   - `.autopilot` — semaphore file (write `run` or `pause`)

4. **Adapt to your agent:** The loop is agent-agnostic. Replace skill names with your agent's equivalents, or use them as-is with Claude Code.

5. **Try the demo:** Clone [**agentflow-demo**](https://github.com/cordsjon/agentflow-demo) — a minimal FastAPI app with pre-filled pipeline stages at every point. Run it, watch the loop, record it.

## Claude Code Skills

Shepherd ships as **34 installable Claude Code skills** in `.claude/skills/`. Copy the skill directories into any project to get the full governance framework as `/sh:` slash commands.

### Installation

**Option A — Copy into your project:**
```bash
cp -r shepherd/.claude/skills/sh-* your-project/.claude/skills/
```

**Option B — Personal skills (all projects):**
```bash
cp -r shepherd/.claude/skills/sh-* ~/.claude/skills/
```

**Option C — Git submodule:**
```bash
cd your-project
git submodule add https://github.com/cordsjon/agentflow .claude/skills/shepherd
```

### Available Skills

| Category | Commands | Description |
|----------|----------|-------------|
| **Pipeline** | `/sh:triage`, `/sh:brainstorm`, `/sh:spec-review`, `/sh:workflow`, `/sh:kickoff` | Inbox processing, ideation, spec quality, queue population, session startup |
| **Loop** | `/sh:autopilot`, `/sh:loop`, `/sh:dor`, `/sh:dod`, `/sh:retro`, `/sh:handoff` | Autonomous execution, quality gates, retrospectives, session persistence |
| **Implementation** | `/sh:plan`, `/sh:execute`, `/sh:tdd`, `/sh:verify`, `/sh:review`, `/sh:finish`, `/sh:worktree`, `/sh:parallel` | Planning, TDD, verification, code review, branch completion, parallel agents |
| **Analysis** | `/sh:analyze`, `/sh:debug`, `/sh:troubleshoot`, `/sh:research`, `/sh:explain`, `/sh:estimate`, `/sh:test`, `/sh:document`, `/sh:index-repo`, `/sh:select-tool` | Code analysis, debugging, research, estimation, documentation |
| **Expert Panels** | `/sh:spec-panel`, `/sh:business-panel` | Multi-expert review (spec gate ≥ 7.0, business advisory) |
| **Persistence** | `/sh:ralph` | Ralph Loop stop-hook for session survival |
| **Meta** | `/sh:cancel`, `/sh:help` | Cancel operations, command reference |

### Skill Structure

Each skill follows this layout:
```
sh-<command>/
├── SKILL.md           # Frontmatter + instructions (loaded by Claude Code)
└── reference.md       # Detailed docs (loaded on demand via markdown links)
```

### Required Project Files

The skills expect these files to exist in your project root:

```
INBOX.md          # Raw input dump
BACKLOG.md        # ## Ideation / ## Refining / ## Ready
TODO-Today.md     # ## Queue (checkbox list)
DONE-Today.md     # Completed items with timestamps
.autopilot        # Semaphore: "run" or "pause"
```

Use the templates in [`templates/`](templates/) to bootstrap them.

## Design Principles

- **Queue-first:** Never implement during triage. Write the queue item first, then execute.
- **Semaphore-controlled:** Agent checks run/pause before every task, not just at session start.
- **Evidence-based completion:** No task is "done" without verification evidence (test output, screenshots).
- **Learnings are part of the fix:** Every bug fix updates the anti-pattern catalog. The fix is incomplete without documentation.
- **Continuous improvement:** Every 10 completed stories triggers a retrospective.

---

## Origin Story

Shepherd didn't start as a product. It started as frustration — a solo developer's side project that evolved through five phases: from YOLO prompting, to checklists, to a structured loop, to a full Scrumban pipeline, to skill integration, and finally the merge of four independent systems (AgentFlow, Superpowers, SuperClaude, Ralph Loop) into one unified framework.

**Read the full story:** [ORIGIN.md](ORIGIN.md)

### What We Learned

1. **Agents don't need freedom — they need guardrails.** The more structure you give an autonomous agent, the better it performs.
2. **Memory is the hardest problem.** Every mechanism in Shepherd exists because forgetting was more expensive than remembering.
3. **Quality gates must be automatic.** If the loop runs tests automatically and halts on failure, quality is guaranteed.
4. **Process scales, heroics don't.** A single developer with Shepherd can sustain output that would normally require a small team.
5. **The best system is the one you actually use.** Three excellent tools requiring three mental models lose to one good tool requiring one.
6. **Skills are the unit of reuse.** Prompt modules that encapsulate expertise for a specific task.
7. **Expert panels are surprisingly effective.** Simulating multiple engineering experts catches things a single-voice review misses.

---

## Expansion: Multi-Agent Communication

Shepherd was designed for a single agent (Claude Code), but the architecture supports multi-agent orchestration through a message bus layer.

### The Problem

Modern AI teams don't use just one model. Claude excels at implementation. Gemini has a million-token context window for research. ChatGPT writes compelling copy. Grok has real-time information. Each agent has strengths, but none can do everything.

### The Architecture

```
                    ┌─────────────────────┐
                    │    Orchestrator     │  Routes tasks to best agent
                    │  (ORCHESTRATOR.md)  │  based on capability scoring
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │    Message Bus      │  Agent-to-agent communication
                    │  (any transport)    │  SQLite, HTTP, pub/sub, etc.
                    └──┬──────┬──────┬────┘
                       │      │      │
                  ┌────▼─┐ ┌─▼────┐ ┌▼──────┐
                  │Claude│ │Gemini│ │ChatGPT│
                  │ACTIVE│ │ STUB │ │ STUB  │
                  └──────┘ └──────┘ └───────┘
```

### How It Works

1. **Capability scoring:** Each agent has a manifest ([AGENT_CAPABILITIES.md](AGENT_CAPABILITIES.md)) listing strengths, context access, and constraints. The orchestrator scores each agent against the task keywords.

2. **Routing confidence:** Score > 0.7 = auto-route. Score 0.3-0.7 = suggest with human confirmation. Score < 0.3 = unroutable.

3. **Message bus transport:** Any communication layer works — HTTP API, SQLite-based messaging, Google Sheets bridge, or manual paste. The framework is transport-agnostic.

4. **Single-agent mode:** When only one agent is active (the common case), the orchestrator still adds value through stall detection, dependency cascading, and context preloading. No message bus needed.

### Tether — The Reference Message Bus

The multi-agent architecture was developed alongside [**Tether**](https://github.com/latentcollapse/Tether), an open-source LLM-to-LLM message bus purpose-built for agent communication.

**What Tether does:**
- **SQLite + BLAKE3** — tamper-evident message storage with content-addressed hashing
- **LC-B encoding** — compact binary format (9 tags) for structured agent messages
- **13 MCP tools** — `tether_send`, `tether_receive`, `tether_inbox`, `tether_thread_create`, `tether_resolve`, `tether_snapshot`, `tether_export`, and more
- **HTTP API** (port 7890) — REST endpoints for agents without MCP support
- **Google Sheets bridge** — enables non-MCP agents (Gemini, ChatGPT) to participate via AppScript + auto-refresh polling
- **Thread model** — conversations grouped by topic with resolve/collapse lifecycle

**How it fits Shepherd:**

```
┌─────────────┐                          ┌─────────────┐
│   Claude     │ ── MCP (13 tools) ────→ │             │
│   @claude    │                          │   Tether    │
│   ACTIVE     │ ←─────────────────────── │   tether.db │
└─────────────┘                          │             │
                                          │  HTTP :7890 │
┌─────────────┐                          │             │
│   Gemini     │ ── Sheets bridge ──────→ │             │
│   @gemini    │                          │             │
│   STUB       │ ←── poll (2 min) ────── │             │
└─────────────┘                          └─────────────┘
```

The orchestrator dispatches tasks via `tether_send(to="@agent", subject="task-assignment")`. Agents report back via `tether_send(to="orchestrator", subject="task-complete")`. In single-agent mode (Claude only), Tether is not required — the loop runs entirely through local file annotation.

**Tether is optional.** Shepherd works without it. But if you want multi-agent communication with tamper-evident message history, thread management, and cross-platform transport, Tether is the reference implementation.

### Building Your Own Multi-Agent Setup

To add a new agent:

1. Add an entry to `AGENT_CAPABILITIES.md` with status `stub`
2. Set up transport (Tether MCP, HTTP API, Sheets bridge, or manual relay)
3. Run the activation checklist:
   - Verify transport (can the agent receive messages?)
   - Complete first contact (successful round-trip via Tether or chosen transport)
   - Send bootstrap context (project overview, conventions)
   - Route one low-risk test task
   - Set routing weight based on observed capability
4. Update status from `stub` to `active`

The orchestrator handles routing automatically once the agent is registered and weighted.

---

## Companion Tools

Shepherd is a set of markdown files and conventions. But two companion tools were built alongside it to make the loop tangible — a GUI remote control and a web-based pipeline dashboard. Both are open-source and can be adapted to any Shepherd project.

### Remote Control — Loop GUI Dashboard

A native desktop GUI (WinForms/PowerShell) that exposes all 30+ loop functions without touching the terminal. Designed for the operator who wants to see what the agent is doing and intervene when needed.

**Dual-mode UI:**
<img width="1574" height="817" alt="image" src="https://github.com/user-attachments/assets/10ce89ef-7d6e-40d1-ae8d-a06189910948" />


```
COMPACT MODE (~420×120 px, always-on-top)
+================================================================+
|  [>] [||] [U] [AB] | Status | [BLD] [RST] [GL] [D] [X]       |
+----------------------------------------------------------------+
|  > [4] US-019 Recipe validation              project v2.1      |
+----------------------------------------------------------------+
|  Action: Medium finding in auth.py — review required           |
+================================================================+

DASHBOARD MODE (~900×700 px)
+============================================================+
|  RC-1.0  [Project v]  INBOX(3) BACKLOG(7) QUEUE(4)          |
+------------------------------------------------------------+
|  PIPELINE (Kanban)                                           |
|  +--------+ +--------+ +--------+ +--------+                |
|  |Inbox(3)| |Ideate 2| |Refine 3| |Ready(2)|                |
+------------------------------------------------------------+
|  QUEUE (TODO-Today)                [Greenlight] [Run]        |
|  > Current: US-019 Recipe valid.    [2/7 done]               |
+------------------------------------------------------------+
|  AUTOPILOT      | SERVER       | SESSION                     |
|  [>Resume] [||] | :9001 UP     | Memory: 2h ago              |
|  [Unattend 2h]  | v2.1.0       | Retro: [===7/10==]          |
+============================================================+
```

**Key capabilities:**
- **Autopilot control** — Resume / Pause / Unattended timer (2h/4h/6h/8h)
- **Queue view** — Live TODO-Today parsing, current task display, progress bar
- **Server health** — TCP port check, build log streaming, git status (M/U counts)
- **Multi-project switching** — Dropdown lists all governed projects, auto-detects active one
- **Action bridge** — GUI writes commands to `.claude-action`, agent reads and executes. One-at-a-time queueing with stale detection (5 min timeout)
- **Hotkeys** — `Win+Shift+T` toggle visibility, `Win+Shift+R` resume, `Win+Shift+P` pause, `Win+Shift+G` greenlight

**Architecture — Single-Writer Rule:**

The critical constraint: the agent is the only writer to pipeline markdown files (BACKLOG, TODO-Today, DONE-Today). The GUI communicates through a `.claude-action` file — a command channel that the agent polls and executes. This eliminates concurrent write hazards entirely.

```
┌──────────┐     .claude-action       ┌──────────┐
│   GUI    │ ──── writes command ───→ │  Agent   │
│ (Remote  │                          │ (Claude  │
│  Control)│ ←── reads  result ────── │  Code)   │
└──────────┘     .claude-action-log   └──────────┘
                                           │
                                    writes to .md files
                                    (BACKLOG, TODO-Today, etc.)
```

**Tech stack:** PowerShell 5.1, WinForms (.NET Framework 4.7.2), no external dependencies. Runs on any Windows 10+ machine.

**Phases:**
1. Core Shell (compact mode, autopilot, queue, health) — **implemented**
2. Pipeline Visibility (Kanban view, INBOX triage, staleness scanner)
3. Outer Loop Controls (BACKLOG graduation, planning rounds, greenlight streaming)
4. PO Intelligence (dependency trees, risk register, retro counter, BV scoring)

---

### Pipeline Dashboard — Web-Based Kanban

A lightweight web dashboard that visualizes the entire Shepherd pipeline as a 6-column Kanban board. Think "Jira for markdown files" — but local, instant, and zero-config.

<img width="3806" height="1942" alt="image" src="https://github.com/user-attachments/assets/e159528d-1547-4077-96bd-653e81231b98" />



**Key features:**
- **6-column Kanban** — maps directly to pipeline stages: Inbox → Ideation → Refining → Ready → Queue → Done
- **Auto-discovery** — scans a root directory for all projects containing pipeline markdown files
- **Project filter** — scope the board to a single project or view all at once
- **Epic accordion** — items grouped by epic prefix, collapse/expand state persisted in localStorage
- **Promote button** — one-click promotion to the next pipeline stage (writes directly to `.md` files)
- **Lane-aware command shortcuts** — each card shows the appropriate `/sh:` command for its stage, copies to clipboard on click
- **Card details** — expand any card to see the full item body (spec links, AC, context)

**Architecture:**
- Pure Python backend (no framework dependency beyond stdlib, or lightweight Flask)
- Vanilla HTML/CSS/JS frontend — no build system, no React/Vue
- No database — reads/writes directly to `.md` files via regex + file I/O
- No authentication — designed for single-user local environments

**How it integrates with Shepherd:**

| Pipeline File | Dashboard Column | Interaction |
|---------------|-----------------|-------------|
| `INBOX.md` | Inbox | View + promote to BACKLOG |
| `BACKLOG.md #Ideation` | Ideation | View + promote to Refining |
| `BACKLOG.md #Refining` | Refining | View + promote to Ready |
| `BACKLOG.md #Ready` | Ready | View + promote to Queue via `/workflow` |
| `TODO-Today.md` | Queue | View current execution state |
| `DONE-Today.md` | Done | View completed items with timestamps |

**Start:**
```bash
python dashboard.py [--port 8500] [--root /path/to/projects]
# Open http://localhost:8500
```

---

### Choosing Between Them

| Feature | Remote Control | Pipeline Dashboard |
|---------|---------------|-------------------|
| **Platform** | Windows (WinForms) | Any (web browser) |
| **Best for** | Real-time operator control | Pipeline visibility + planning |
| **Autopilot control** | Yes (resume/pause/unattended) | No |
| **Server health** | Yes (TCP check, build log) | No |
| **Kanban view** | Phase 2+ | Yes (6 columns) |
| **Multi-project** | Yes (dropdown) | Yes (auto-discover) |
| **Promote items** | Via action bridge (agent writes) | Direct file write |
| **Always-on-top** | Yes (compact mode) | No |
| **Zero dependencies** | PowerShell 5.1 + .NET | Python + browser |

Use **both** together: Remote Control for moment-to-moment autopilot management, Pipeline Dashboard for planning rounds and backlog grooming.

---

## License

MIT — see [LICENSE](LICENSE).
