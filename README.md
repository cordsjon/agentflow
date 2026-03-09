# agentflow

**AI-governed Scrumban loop for autonomous dev agents.**

A governance framework that gives AI coding agents (Claude Code, Cursor, Codex, Devin, etc.) a structured execution loop with quality gates, dependency tracking, and autonomous task processing — while keeping humans in control.

---

## What is this?

Most AI coding agents run in one of two modes: fully manual (you prompt every step) or fully autonomous (YOLO). **agentflow** provides the middle ground — a Scrumban pipeline where:

- **Agents execute autonomously** within a bounded loop (pick task, implement, test, commit)
- **Quality gates halt execution** when issues exceed thresholds (no silent failures)
- **Humans control the queue** (what gets built, in what order, with what priority)
- **Skills plug into loop stages** (code review, TDD, security audit — each wired to a specific step)

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

Skills (reusable prompt modules) plug into specific loop stages:

| Loop Stage | Skills |
|------------|--------|
| Execute | `/test-driven-development` |
| Verify | `/verification-before-completion` |
| Review | `/requesting-code-review`, `/receiving-code-review` |
| Cleanup | `/clean-code`, `/production-code-audit` |
| Commit | `/commit-smart` |
| Branch | `/finishing-a-development-branch` |
| Context | `/session-handoff` |
| Retro | `/kaizen` |
| Refine | `/requirements-clarity` |

Plus 4 support process portfolios (GTM, SEO, Intel, Content) and an on-demand toolbox — see [GOVERNANCE-GUIDE.md](GOVERNANCE-GUIDE.md) §12.

## Getting Started

1. **Copy these files** into your project's `governance/` directory
2. **Reference from your CLAUDE.md** (or equivalent agent instructions):
   ```markdown
   ## Governance
   This project follows the agentflow loop.
   See governance/CLAUDE-LOOP.md for execution model.
   ```
3. **Create your pipeline files:**
   - `INBOX.md` — raw input dump
   - `BACKLOG.md` — with `## Ideation`, `## Refining`, `## Ready` sections
   - `TODO-Today.md` — with `## Queue` section
   - `DONE-Today.md` — completion log
   - `.autopilot` — semaphore file (write `run` or `pause`)

4. **Adapt to your agent:** The loop is agent-agnostic. Replace skill names with your agent's equivalents, or use them as-is with Claude Code.

## Design Principles

- **Queue-first:** Never implement during triage. Write the queue item first, then execute.
- **Semaphore-controlled:** Agent checks run/pause before every task, not just at session start.
- **Evidence-based completion:** No task is "done" without verification evidence (test output, screenshots).
- **Learnings are part of the fix:** Every bug fix updates the anti-pattern catalog. The fix is incomplete without documentation.
- **Continuous improvement:** Every 10 completed stories triggers a retrospective.

---

## Origin Story

agentflow started as a simple TODO list and a CLAUDE.md file in a solo developer's side project — an SVG asset generation platform built with FastAPI and Claude Code.

### The Humble Beginning

**Phase 0 — The "just ship it" era.**
No process. Prompt Claude, get code, paste it, hope it works. Context lost between sessions. Same bugs reintroduced. Same anti-patterns rediscovered. The agent was powerful but amnesiac.

**Phase 1 — The checklist.**
A `TODO-Today.md` file. A simple `DONE-Today.md` to track what shipped. A `CLAUDE.md` with rules like "don't use bare except" and "always run tests before commit." Better, but still reactive — rules were added after each painful bug, not before.

**Phase 2 — The loop.**
The realization that autonomous agents need _structure_, not just instructions. The inner loop emerged: pick task → implement → test → commit → next. Then the semaphore (`.autopilot` file) — a kill switch for when the agent goes off track. Then the cleanup sub-loop — quality gates that halt execution on medium+ severity findings.

**Phase 3 — The pipeline.**
Work items need to mature before implementation. INBOX for raw dumps. BACKLOG with Ideation → Refining → Ready stages. Definition of Ready (DOR) as an entry gate. Definition of Done (DOD) as an exit gate. Graduation commands to move items through the pipeline with quality checks at each transition.

**Phase 4 — The skills.**
Repeatable prompt modules that plug into specific loop stages. Test-driven development at step 6. Verification at step 7. Code review at step 8. Each skill encapsulates expertise that would otherwise be lost between sessions. 60+ skills organized into dev loop, support processes, and an on-demand toolbox.

**Phase 5 — The governance layer.**
One project became many. The loop needed to be consistent across all of them. A central Governance repo with synced copies. An orchestrator for multi-agent routing. Known patterns that travel between projects. Retrospectives every 10 stories that feed improvements back into the system.

### What We Learned

1. **Agents don't need freedom — they need guardrails.** The more structure you give an autonomous agent, the better it performs. Not because it's dumb, but because structure prevents drift.

2. **Memory is the hardest problem.** Context windows compress, sessions end, conversations get lost. Every mechanism in agentflow exists because forgetting was more expensive than remembering.

3. **Quality gates must be automatic.** If a human has to remember to run tests, tests won't get run. If the loop runs tests automatically and halts on failure, quality is guaranteed.

4. **Process scales, heroics don't.** A single developer with agentflow can sustain output that would normally require a small team — but only because the process catches what the human would miss.

---

## Expansion: Multi-Agent Communication

agentflow was designed for a single agent (Claude Code), but the architecture supports multi-agent orchestration through a message bus layer.

### The Problem

Modern AI teams don't use just one model. Claude excels at implementation. Gemini has a million-token context window for research. ChatGPT writes compelling copy. Grok has real-time information. Each agent has strengths, but none can do everything.

### The Architecture

```
                    ┌─────────────────────┐
                    │    Orchestrator      │  Routes tasks to best agent
                    │  (ORCHESTRATOR.md)   │  based on capability scoring
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │    Message Bus       │  Agent-to-agent communication
                    │  (any transport)     │  SQLite, HTTP, pub/sub, etc.
                    └──┬──────┬──────┬────┘
                       │      │      │
                  ┌────▼─┐ ┌─▼────┐ ┌▼─────┐
                  │Claude│ │Gemini│ │ChatGPT│
                  │ACTIVE│ │ STUB │ │ STUB  │
                  └──────┘ └──────┘ └───────┘
```

### How It Works

1. **Capability scoring:** Each agent has a manifest ([AGENT_CAPABILITIES.md](AGENT_CAPABILITIES.md)) listing strengths, context access, and constraints. The orchestrator scores each agent against the task keywords.

2. **Routing confidence:** Score > 0.7 = auto-route. Score 0.3-0.7 = suggest with human confirmation. Score < 0.3 = unroutable.

3. **Message bus transport:** Any communication layer works — HTTP API, SQLite-based messaging, Google Sheets bridge, or manual paste. The framework is transport-agnostic.

4. **Single-agent mode:** When only one agent is active (the common case), the orchestrator still adds value through stall detection, dependency cascading, and context preloading. No message bus needed.

### Building Your Own Multi-Agent Setup

To add a new agent:

1. Add an entry to `AGENT_CAPABILITIES.md` with status `stub`
2. Set up transport (message bus, HTTP, or manual relay)
3. Run the activation checklist:
   - Verify transport (can the agent receive messages?)
   - Complete first contact (round-trip message)
   - Send bootstrap context (project overview, conventions)
   - Route one low-risk test task
   - Set routing weight based on observed capability
4. Update status from `stub` to `active`

The orchestrator handles routing automatically once the agent is registered and weighted.

---

## License

MIT — see [LICENSE](LICENSE).
