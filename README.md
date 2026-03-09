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

## License

MIT — see [LICENSE](LICENSE).
