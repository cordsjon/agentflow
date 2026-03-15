# Shepherd — Unified AI Agent Governance Framework

**Date:** 2026-03-12
**Status:** Design
**Author:** Jonas Cords + Claude

---

## 1. Problem

Three independent systems — Ralph Loop (persistence), SuperClaude (skill library), and AgentFlow (governance pipeline) — each solve a different layer of the same problem: giving AI agents structured, quality-gated, persistent autonomous execution.

Using all three requires knowing three brands, three namespaces, three install methods, and manually wiring them together. Duplicate skills exist across systems (brainstorm, workflow, session lifecycle). Users must understand which system provides which capability.

## 2. Solution

**Shepherd** merges the best of all three into a single product:

- **AgentFlow's** Scrumban pipeline and quality gates become the backbone
- **Superpowers'** execution skills plug into loop steps as first-class built-ins
- **SuperClaude's** analysis/utility skills and expert panels become on-demand tools
- **Ralph Loop's** stop-hook persistence wraps the autopilot for session survival

One install. One namespace (`/sh:`). One product.

## 3. Architecture

```
┌─────────────────────────────────────────────────────┐
│  Ralph Layer (persistence)                           │
│  Stop hook intercepts exit, re-feeds prompt           │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │  AgentFlow Engine (governance)                   │ │
│  │  Pipeline: INBOX → BACKLOG → TODO → DONE         │ │
│  │  14-step inner loop + semaphore + gates           │ │
│  │                                                   │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │  Skills Layer                                │ │ │
│  │  │  Superpowers: execution (TDD, verify, etc.) │ │ │
│  │  │  SuperClaude: analysis (research, panels)   │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  On exit → Ralph re-feeds → kickoff restores context │
└─────────────────────────────────────────────────────┘
```

### 3.1 Layer Responsibilities

| Layer | System Origin | Responsibility |
|-------|--------------|----------------|
| **Persistence** | Ralph Loop | Session survival via stop hook. Re-invokes prompt on exit. Iteration counting, completion promise detection. |
| **Governance** | AgentFlow | Pipeline stages, semaphore control, 14-step inner loop, DOR/DOD gates, orchestrator routing, FIPD taxonomy, retro cycle. |
| **Skills** | Superpowers + SuperClaude | Expert prompts for each loop step. Pluggable, replaceable, extensible. |
| **Panels** | SuperClaude | Extensible expert registry (`experts/` directory) for multi-perspective analysis. |

### 3.2 How Ralph Wraps Autopilot

```
User invokes: /sh:ralph "complete backlog items" --max-iterations 50

Ralph creates .claude/ralph-loop.local.md (state file)
  → Claude starts /sh:autopilot
    → Loop runs: pick task → execute → verify → commit → next
    → Queue empties or semaphore = pause → Claude tries to exit
  → Ralph stop hook intercepts exit
  → Re-feeds same prompt
  → /sh:kickoff (step 2) reads context from last /sh:handoff (step 13)
  → Loop resumes seamlessly
```

The key contract: **step 13 (context save) always runs before exit**, so step 2 (context load) always has fresh state. Ralph doesn't need to understand the loop — it just prevents exit.

## 4. Pipeline Flow

```
INBOX.md ──/sh:triage──▶ BACKLOG.md ──/sh:workflow──▶ TODO-Today.md ──/sh:autopilot──▶ DONE-Today.md
                              │
                    ┌─────────┴──────────┐
                    │  Refining Stage     │
                    │  /sh:brainstorm     │  Ideation → Refining
                    │  /sh:spec-review    │  Refining → Ready (gate: ≥7.0)
                    └────────────────────┘
```

### 4.1 Spec Review — Two-Stage Gate

```
Spec written
    │
    ▼
Stage 1: Quick Review (Superpowers reviewer)
    - TODOs/placeholders?
    - Missing sections?
    - Internal contradictions?
    - YAGNI violations?
    Pass/Fail — loops up to 5x until clean
    │
    ▼
Stage 2: Expert Panel (SC spec-panel)
    - 10 expert perspectives (from experts/ registry)
    - Quality scores: clarity, completeness, testability, consistency
    - Discussion/Critique/Socratic modes
    - Score ≥ 7.0 = Ready
    │
    ▼
Ready ✅ → eligible for /sh:workflow
```

**Failure handling:** If Stage 1 fails 5 consecutive times (spec keeps failing the completeness check), the process pauses for human review — the spec likely has a structural problem that automated fixes can't resolve. Stage 2 failures (score < 7.0) follow the panel's `--iterations` parameter for iterative improvement, then pause for human review if the score remains below threshold.

## 5. Inner Loop — 14 Steps

| Step | Action | Skill Invoked |
|------|--------|---------------|
| 1 | Check `.autopilot` semaphore | (built-in) |
| 2 | Context load | `/sh:kickoff` |
| 3 | Read first unchecked task | (built-in) |
| 4 | Route — orchestrator phase (see §5.3) | (auto, see §5.3) |
| 5 | DOR gate check | `/sh:dor` (auto) |
| 6 | Execute — TDD for code tasks, direct execute for non-code (see §5.4) | `/sh:tdd` → `/sh:execute` |
| 7 | Verify — evidence-based AC check | `/sh:verify` |
| 8 | Review — self-review changed files | `/sh:review` |
| 9 | Cleanup — fix Low findings, FIPD classify | `/sh:analyze` + FIPD (auto) |
| 10 | Commit — atomic, per DOD | `/sh:dod` (auto) |
| 11 | Branch — PR/merge if feature branch | `/sh:finish` |
| 12 | Done — move to DONE-Today, cascade deps | (built-in) |
| 13 | Context save — produces `HANDOVER.md` (see §5.6) | `/sh:handoff` |
| 14 | Next task or stop | (built-in) |

### 5.1 Cleanup Sub-Loop (nested in step 9)

```
run greenlight → review findings

if task size ≥ M:
    run deep audit (security/perf/arch)

while Low findings exist:
    fix each Low finding
    re-run greenlight

if Medium or High findings remain:
    write finding summary to .claude-action
    write "pause" to .autopilot
    STOP — human review required
```

### 5.2 Key Invariants

- No commit without greenlight — always, no exceptions
- Medium+ findings pause autopilot — never downgrade, never bypass
- Semaphore checked before EVERY task — not just at session start
- Context saved before EVERY exit — Ralph depends on this

### 5.3 Orchestrator Routing (Step 4)

The orchestrator is a **phase**, not a daemon. It runs at two trigger points:

**At cycle start** (after reading the next task, before DOR check):
1. **Stall check** — has this task been attempted before without progress? If stall counter ≥ 3, flag for human review
2. **Assignment** — score each registered agent in `AGENT_CAPABILITIES.md` against task keywords. Score > 0.7 = auto-assign. Score 0.3-0.7 = suggest. Score < 0.3 = unroutable. In single-agent mode (Claude only), this annotates the task with context hints
3. **Dependency scan** — check BACKLOG for items with `needs: <completed_item>` that are now unblocked
4. **Context preload** — assemble file references, risk flags, and prior art into `_Context:_` annotation

**At task completion** (after moving item to DONE-Today):
1. **Dependency cascade** — unblock items that depended on the completed task
2. **Stall reset** — clear stall counter
3. **Queue check** — if ≤ 1 unchecked item remains, suggest a planning round

Full routing logic defined in [ORCHESTRATOR.md](../../ORCHESTRATOR.md).

### 5.4 Execute Step Decision Tree (Step 6)

```
Is this task a User Story with code changes?
  YES → invoke /sh:tdd first (write failing test), then /sh:execute
  NO  → is it a documentation, config, or process task?
    YES → invoke /sh:execute directly (no TDD)
    NO  → is it a bug fix?
      YES → invoke /sh:debug first, then /sh:tdd, then /sh:execute
      NO  → invoke /sh:execute directly
```

Step 11 (`/sh:finish`) is a **no-op when working on main/master directly** — it only activates when the current branch is a feature branch.

### 5.5 Task Sizing

Tasks are sized by the **queue author** during `/sh:workflow` and annotated on the queue item:

| Size | Label | Criteria | Cleanup Behavior |
|------|-------|----------|-----------------|
| **S** | Small | Single file, < 50 lines changed, no new modules | Greenlight only |
| **M** | Medium | 2-5 files, new functions/classes, < 500 lines | Greenlight + deep audit |
| **L** | Large | New modules, API changes, > 500 lines, schema migrations | Greenlight + deep audit + mandatory human review |

If no size annotation is present, the orchestrator infers size from the task description keywords and DOR complexity signals. Default: **M** (Medium).

### 5.6 Ralph State File Contract

The Ralph state file (`.claude/ralph-loop.local.md`) uses YAML frontmatter:

```yaml
---
active: true
iteration: 1
session_id: <claude-session-id>
max_iterations: 50          # 0 = unlimited
completion_promise: "DONE"  # null = no promise
started_at: "2026-03-12T14:30:00Z"
---

<original prompt text>
```

The **handoff document** (`HANDOVER.md`) produced by step 13 contains:

```markdown
## Handover State
- **Last completed task:** <task description>
- **Queue position:** <N of M remaining>
- **Git state:** branch, last commit SHA, modified files
- **Decisions made:** <list of decisions this iteration>
- **Open questions:** <unresolved items>
- **Resume checklist:** <what step 2 should restore>
```

Ralph reads `iteration:` to enforce `max_iterations`. The autopilot reads `HANDOVER.md` to restore context. These are independent — Ralph owns the loop counter, autopilot owns the work state.

### 5.7 FIPD Finding Taxonomy

Every finding from `/sh:analyze` or the cleanup sub-loop is classified by **action type**:

| Action | Definition | What to Do |
|--------|-----------|------------|
| **Fix** | Root cause known, solution clear | Implement immediately |
| **Investigate** | Symptom observed, root cause unknown | Gather data, diagnose |
| **Plan** | Issue understood, needs design | Add to backlog, estimate |
| **Decide** | Trade-off identified, multiple valid paths | Escalate to human |

Fix findings are resolved in the cleanup sub-loop. Investigate/Decide findings must include an `Unknown:` clause explaining what information is missing. Plan findings are added to BACKLOG#Ideation.

## 6. Command Namespace

All commands under `/sh:` prefix (34 total).

### 6.1 Pipeline

| Command | Description |
|---------|-------------|
| `/sh:triage` | Route INBOX items into BACKLOG pipeline |
| `/sh:brainstorm` | Requirements discovery through Socratic dialogue |
| `/sh:spec-review` | Two-stage spec review (quick + expert panel) |
| `/sh:workflow` | Generate TODO-Today queue from BACKLOG#Ready |
| `/sh:kickoff` | Daily session startup scan |

### 6.2 Loop Execution

| Command | Description |
|---------|-------------|
| `/sh:autopilot` | Start autonomous 14-step loop |
| `/sh:loop` | Execute single loop iteration |
| `/sh:dor` | Definition of Ready gate check |
| `/sh:dod` | Definition of Done gate check |
| `/sh:retro` | Retrospective every 10 stories |
| `/sh:handoff` | Context save for session continuity |

### 6.3 Implementation Skills

| Command | Description |
|---------|-------------|
| `/sh:plan` | Create implementation plan from spec |
| `/sh:execute` | Execute plan with review checkpoints |
| `/sh:tdd` | Test-driven development cycle |
| `/sh:verify` | Evidence-based acceptance criteria verification |
| `/sh:review` | Request + receive code review |
| `/sh:finish` | Branch completion (PR/merge/cleanup) |
| `/sh:worktree` | Isolated git worktrees |
| `/sh:parallel` | Dispatch parallel subagents |

### 6.4 Analysis & Utility

| Command | Description |
|---------|-------------|
| `/sh:analyze` | Code quality/security/performance scan |
| `/sh:debug` | Systematic bug diagnosis |
| `/sh:troubleshoot` | Issue resolution for builds/deploys/systems |
| `/sh:research` | Deep web research with parallel search |
| `/sh:explain` | Educational code explanations |
| `/sh:estimate` | Development effort estimation |
| `/sh:test` | Test execution with coverage analysis |
| `/sh:document` | Targeted documentation generation |
| `/sh:index-repo` | Repository indexing for token reduction |
| `/sh:select-tool` | MCP tool recommendation |

### 6.5 Expert Panels

| Command | Description |
|---------|-------------|
| `/sh:spec-panel` | Multi-expert spec review with scoring (gate: ≥7.0) |
| `/sh:business-panel` | Multi-expert business analysis (advisory) |

### 6.6 Persistence

| Command | Description |
|---------|-------------|
| `/sh:ralph` | Start persistent Ralph loop |
| `/sh:cancel` | Cancel active Ralph loop |

### 6.7 Meta

| Command | Description |
|---------|-------------|
| `/sh:help` | List all Shepherd commands |

## 7. Expert Panel System

Extensible file-based registry for panel expertise.

### 7.1 Directory Structure

```
experts/
├── registry.yaml              # Auto-generated master index
├── panels/                    # Panel definitions (YAML)
│   ├── spec-panel.yaml        # 10 experts, scoring gate
│   └── business-panel.yaml    # 9 experts, advisory
├── packs/                     # Thematic bundles
│   ├── core-engineering.md    # Fowler, Nygard, Newman, Hohpe
│   ├── core-requirements.md   # Wiegers, Adzic, Cockburn
│   ├── core-testing.md        # Crispin, Gregory, Adzic
│   ├── core-business.md       # All 9 business experts
│   └── solo-creator.md        # Etsy/POD domain (ideation)
├── individuals/               # One file per expert
│   ├── _TEMPLATE.md
│   └── [19 expert files]
└── scripts/
    └── rebuild-registry.sh    # Regenerates registry from files
```

### 7.2 Adding Experts

1. Copy `individuals/_TEMPLATE.md` → `individuals/your-expert.md`
2. Fill in frontmatter (name, domain, methodology, panels, keywords, token-cost)
3. Write Critique Voice, Perspective, Interaction Style
4. Run `./scripts/rebuild-registry.sh`
5. Add expert slug to relevant panel YAML `default-experts` or `auto-select` rules

### 7.3 Auto-Select

Panels define keyword rules that dynamically add experts based on task content:

```yaml
auto-select:
  - keywords: [api, rest, graphql, microservice]
    add: [sam-newman]
  - keywords: [etsy, print, svg]
    add-pack: solo-creator
```

Max panel size (default: 6) enforces token budget. When auto-select would exceed the cap:

1. Default experts are never displaced — they always sit on the panel
2. Auto-selected experts fill remaining slots in keyword-match-score order
3. If all slots are full, additional auto-selected experts are listed in the output as "considered but excluded (panel full)" so the user can override with `--experts`

### 7.4 Creating New Panels

Copy `panels/_TEMPLATE.yaml`. Define default experts, focus areas, auto-select
rules, and scoring (null for advisory panels, threshold for gate panels).

## 8. What Was Dropped

### 8.1 From SuperClaude (12 dropped)

| Dropped | Reason |
|---------|--------|
| `/sc:brainstorm` | Superpowers `brainstorming` is richer (hard gate, visual companion, spec review loop) |
| `/sc:workflow` | AgentFlow's is pipeline-aware |
| `/sc:pm` | AgentFlow orchestrator has routing + scoring |
| `/sc:spawn` | Covered by `/sh:parallel` |
| `/sc:git` | Covered by commit skills + DOD gate |
| `/sc:load` | Covered by `/sh:kickoff` (loop step 2) |
| `/sc:save` | Covered by `/sh:handoff` (loop step 13) |
| `/sc:reflect` | Covered by `/sh:retro` |
| `/sc:sc` | Meta-dispatcher for SC brand — gone |
| `/sc:help` | Replaced by `/sh:help` |
| `/sc:recommend` | SC command recommender — moot |
| `/sc:README` | Install docs for SC — moot |

### 8.2 From Superpowers (3 dropped)

| Dropped | Reason |
|---------|--------|
| `using-superpowers` | Skill router for Superpowers brand — Shepherd has its own |
| `writing-skills` | Authoring tool, not execution loop |
| `subagent-driven-development` | Overlaps with `dispatching-parallel-agents` + `executing-plans` |

### 8.3 From AgentFlow (0 dropped)

Everything kept. AgentFlow is the backbone.

## 9. Merge Decisions

### 9.1 Brainstorm: Superpowers wins

Superpowers' `brainstorming` kept over SC's `/sc:brainstorm` because:
- End-to-end flow (requirements through design, spec review, handoff to planning)
- Hard gate against premature implementation
- Visual companion for mockups
- Scope decomposition for oversized requests
- YAGNI principle enforced

SC's multi-persona analysis and requirements-only mode are candidates for future enhancement.

### 9.2 Spec Review: Both kept, chained

Superpowers' lightweight reviewer runs first (fast pre-filter for completeness).
SC's spec-panel runs second (deep expert review with scoring).
Combined into single `/sh:spec-review` command.

### 9.3 Session Lifecycle: AgentFlow wins

Loop step 2 (context load via `/sh:kickoff`) and step 13 (context save via `/sh:handoff`)
replace SC's `/sc:load` and `/sc:save`. The loop-integrated version ensures context
is always saved before exit — critical for Ralph persistence.

### 9.4 Code Review: Superpowers wins

Two complementary skills: `/sh:review` combines `requesting-code-review` (self-review)
and `receiving-code-review` (respond to external feedback). Mapped to loop step 8.

## 10. Installation

### 10.1 Skill File Convention

Each Shepherd skill is a directory under `.claude/skills/`:

```
.claude/skills/
├── sh-autopilot/
│   ├── SKILL.md          # Frontmatter + instructions (loaded by Claude Code)
│   └── reference.md      # Detailed docs (loaded on demand)
├── sh-triage/
│   ├── SKILL.md
│   └── reference.md
├── sh-brainstorm/
│   ├── SKILL.md
│   ├── reference.md
│   └── visual-companion.md
└── ...
```

Naming convention: `sh-<command-name>/SKILL.md`. The `SKILL.md` frontmatter contains:
```yaml
---
name: sh:<command-name>
description: "One-line description"
disable-model-invocation: true  # for loop/autopilot skills that should not auto-trigger
---
```

### 10.2 As Claude Code Skills (per-project)

```bash
cp -r shepherd/.claude/skills/sh-* your-project/.claude/skills/
```

### 10.3 As Personal Skills (all projects)

```bash
cp -r shepherd/.claude/skills/sh-* ~/.claude/skills/
```

### 10.4 Required Project Files

```
INBOX.md          # Raw input dump
BACKLOG.md        # ## Ideation / ## Refining / ## Ready
TODO-Today.md     # ## Queue (checkbox list)
DONE-Today.md     # Completed items with timestamps
.autopilot        # Semaphore: "run" or "pause"
```

### 10.5 Expert Registry (optional)

```bash
cp -r shepherd/experts/ your-project/experts/
```

## 11. Migration from Existing Systems

### 11.1 From AgentFlow

- Rename `/agentflow-*` commands to `/sh:*` equivalents
- Expert registry is new — copy `experts/` directory
- Pipeline files (INBOX, BACKLOG, TODO-Today, DONE-Today, .autopilot) unchanged

### 11.2 From SuperClaude

- Uninstall: `superclaude uninstall` (removes `~/.claude/commands/sc/`)
- `/sc:spec-panel` → `/sh:spec-panel` (expert files now in `experts/`)
- `/sc:business-panel` → `/sh:business-panel`
- `/sc:analyze` → `/sh:analyze`
- Other SC commands have Shepherd equivalents or are dropped

### 11.3 From Superpowers

- Superpowers plugin can coexist (Shepherd skills take precedence by name)
- Or uninstall: remove from `~/.claude/plugins/`

## 12. Future Work

- **Consulting panel** — new panel type for business consulting engagements
- **Solo Creator pack** — promote from ideation to full individual expert files
- **Community expert packs** — installable from git repos
- **Panel auto-select phase 2** — semantic matching beyond keywords
- **Tether integration** — multi-agent message bus ([github.com/latentcollapse/Tether](https://github.com/latentcollapse/Tether)) enabling cross-agent communication for orchestrator routing beyond single-agent mode
- **Pipeline Dashboard** — web-based Kanban board that reads pipeline markdown files and visualizes them as a 6-column board (INBOX → Ideation → Refining → Ready → Queue → Done)
- **Remote Control** — native desktop GUI for autopilot management (resume/pause/unattended timer), queue visibility, and server health — macOS port of existing Windows WinForms implementation
