# Skills Reference — agentflow

> Complete catalog of skills integrated into the governance loop.
> Each skill is a reusable prompt module that plugs into a specific loop stage.

---

## Skill Dependencies & Prerequisites

Skills don't run in isolation — they depend on pipeline state and often chain together.

### Dependency Map

```
                    ┌─────────────────┐
                    │  /sc:brainstorm  │  Ideation → Refining
                    └────────┬────────┘
                             │
                    ┌────────▼────────────────┐
                    │  /requirements-clarity   │  Catch ambiguities
                    └────────┬────────────────┘
                             │
                    ┌────────▼────────┐
                    │  /sc:spec-panel  │  Refining → Ready (gate: >= 7.0)
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   /sc:workflow   │  Ready → TODO-Today queue
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  /sh:ux-design  │  (if user flow exists)
                    │  wireframe →    │  validate → graduate
                    │  /frontend-     │  → hi-fi on top
                    │   design        │
                    └────────┬────────┘
                             │
              ┌──────────────▼──────────────┐
              │        INNER LOOP           │
              │                             │
              │  ┌───────────────────────┐  │
              │  │ /test-driven-dev      │  │  Step 6: Write test first
              │  └──────────┬────────────┘  │
              │             ▼               │
              │  ┌───────────────────────┐  │
              │  │ /verification         │  │  Step 7: Verify ACs
              │  └──────────┬────────────┘  │
              │             ▼               │
              │  ┌───────────────────────┐  │
              │  │ /requesting-review    │  │  Step 8: Self-review
              │  │ /receiving-review     │  │
              │  └──────────┬────────────┘  │
              │             ▼               │
              │  ┌───────────────────────┐  │
              │  │ CLEANUP SUB-LOOP      │  │  Step 9: Quality gate
              │  │  /sc:analyze          │  │
              │  │  /production-code-audit│ │  (M+ tasks only)
              │  │  /sc:cleanup          │  │  (enforces /clean-code)
              │  └──────────┬────────────┘  │
              │             ▼               │
              │  ┌───────────────────────┐  │
              │  │ /commit-smart         │  │  Step 10: Atomic commit
              │  └──────────┬────────────┘  │
              │             ▼               │
              │  ┌───────────────────────┐  │
              │  │ /finishing-branch     │  │  Step 11: PR + merge
              │  └──────────┬────────────┘  │
              │             ▼               │
              │  ┌───────────────────────┐  │
              │  │ /session-handoff      │  │  Step 13: Save context
              │  └───────────────────────┘  │
              └─────────────────────────────┘
                             │
                      every 10 stories
                             │
                    ┌────────▼────────┐
                    │    /kaizen      │  Retrospective
                    └─────────────────┘
```

### Prerequisites per Skill

| Skill | Requires | Produces |
|-------|----------|----------|
| `/sc:brainstorm` | Raw idea in INBOX or BACKLOG#Ideation | Requirements document |
| `/requirements-clarity` | Brainstorm output exists | Ambiguity report, clarified requirements |
| `/sc:spec-panel` | Spec document with US + AC | Score (gate: >= 7.0), improvement suggestions |
| `/sh:ux-design` | User flow (Figma/Miro/PRD), optional business-panel brief | Clickable wireframe prototype, component mapping, handoff doc |
| `/sc:design` | Requirements doc (architecture tasks) | Architecture specification |
| `/sc:workflow` | Ready items in BACKLOG | Populated TODO-Today.md queue |
| `/test-driven-development` | Task in queue with clear AC | Failing test file |
| `/verification-before-completion` | Implementation complete, tests passing | Evidence log (test output, screenshots) |
| `/requesting-code-review` | Changed files in working tree | Review findings |
| `/receiving-code-review` | Review feedback received | Applied fixes |
| `/sc:analyze` | Implementation complete | Quality findings (Low/Medium/High) |
| `/production-code-audit` | Task size >= M (Medium) | Security/perf/arch findings |
| `/sc:cleanup` | Findings from `/sc:analyze` | Fixed code, clean findings |
| `/commit-smart` | Clean greenlight, all findings resolved | Atomic commit |
| `/finishing-a-development-branch` | On a feature branch, commit done | PR created, branch strategy decided |
| `/session-handoff` | Task(s) complete or session ending | HANDOVER.md with resume checklist |
| `/kaizen` | 10 User Stories completed since last retro | Actionable improvement items |

---

## Skill Chains

Common sequences of skills that execute together as workflows.

### Chain 1: Graduation Pipeline
**Trigger:** New idea needs to become implementable work.

```
/sc:brainstorm "idea description" --depth deep
    ↓ produces requirements doc
/requirements-clarity
    ↓ catches ambiguities, iterates
/sc:spec-panel requirements/SPEC.md --mode critique --focus requirements
    ↓ gate: score >= 7.0 (else iterate)
/sc:workflow requirements/SPEC.md --strategy systematic
    ↓ populates TODO-Today.md queue
```

**Example:**
```
User sends: "We need dark mode support"

1. /sc:brainstorm "dark mode support" --depth deep
   → Outputs requirements doc with scope, edge cases, themes

2. /requirements-clarity
   → Catches: "Does dark mode apply to exported assets or just UI?"
   → Clarifies: UI only, export uses explicit color schemes

3. /sc:spec-panel requirements/SPEC_DARK_MODE.md --mode critique
   → Score: 7.5/10 — Ready

4. /sc:workflow requirements/SPEC_DARK_MODE.md --strategy systematic
   → Generates 5 queue items in TODO-Today.md
```

---

### Chain 1b: UX Wireframe Pipeline
**Trigger:** Feature has a multi-step user flow (onboarding, checkout, wizard, form).

```
/sh:business-panel "feature PRD" --focus competitive
    ↓ strategic constraints (JTBD, ICP, risk flags)
/sh:ux-design <figma-url or PRD>
    ↓ Phase 1-3: ingest flow → plan → generate wireframe
    ↓ Phase 4-5: concept branching → compare & decide
    ↓ Phase 6-8: iterate → graduation gate
/frontend-design
    ↓ builds hi-fi ON TOP of wireframe (no restart)
/sh:plan
    ↓ implementation plan for remaining backend/integration work
```

**Example:**
```
User sends: "We need an onboarding wizard for new users"

1. /sh:business-panel requirements/PRD_ONBOARDING.md --focus growth
   → Christensen: JTBD = "get first meeting scheduled within 5 min"
   → Godin: "reduce steps to under 5 — each step is a drop-off cliff"
   → Taleb: "if OAuth fails, user is stuck — mandatory fallback"

2. /sh:ux-design figma.com/board/abc123
   → Generates clickable 5-step wireframe in React (target stack)
   → Playwright smoke test: all steps clickable, no dead ends
   → User: "Give me option B as chat-based onboarding"
   → Concept B generated, comparison table, user picks chat-based

3. /frontend-design
   → Replaces grayscale with design tokens, placeholders with components
   → Preserves flow structure and navigation from wireframe

4. /sh:plan
   → Plans backend API, auth integration, analytics events
```

---

### Chain 2: Implementation Cycle (per task)
**Trigger:** First unchecked `- [ ]` item in TODO-Today.md.

```
/test-driven-development
    ↓ write failing test
[implement until test passes]
    ↓
/verification-before-completion
    ↓ verify ACs with evidence
/requesting-code-review
    ↓ self-review changed files
/receiving-code-review (if issues found)
    ↓ apply fixes
```

**Example:**
```
Task: "- [ ] Implement US-DM-01: CSS custom property theme tokens"

1. /test-driven-development
   → Creates tests/test_dark_mode_tokens.py
   → Tests assert :root has --bg-primary, --text-primary, etc.
   → Tests fail (tokens don't exist yet)

2. [Implementation]
   → Add CSS custom properties to shell.css
   → Tests pass

3. /verification-before-completion
   → Evidence: test output (5/5 pass), screenshot of both themes

4. /requesting-code-review
   → Reviews shell.css changes
   → Finding: "hardcoded fallback #fff should use var(--bg-default)"

5. /receiving-code-review
   → Evaluates finding: valid, applies fix
```

---

### Chain 3: Quality Tail (mandatory, end of every batch)
**Trigger:** Implementation complete, before commit.

```
/sc:analyze "<changed files>" --focus quality
    ↓ identifies findings (Low/Medium/High)
/production-code-audit (if task size >= M)
    ↓ deep security/perf/architecture scan
/sc:cleanup --type all
    ↓ fixes Low findings, enforces /clean-code
[if Medium+ findings: STOP — human review]
    ↓
/commit-smart
    ↓ atomic conventional commit
/finishing-a-development-branch (if on feature branch)
    ↓ PR creation, merge strategy
```

**Example:**
```
Changed files: app/services/theme_service.py, app/static/css/shell.css

1. /sc:analyze "app/services/theme_service.py app/static/css/shell.css"
   → 2 Low findings: missing type hint, unused import

2. /production-code-audit (task was Medium)
   → No security issues, no perf concerns

3. /sc:cleanup --type all
   → Fixes: adds type hint, removes unused import
   → Re-runs greenlight: all green

4. /commit-smart
   → "feat(theme): add CSS custom property tokens for dark mode"

5. /finishing-a-development-branch
   → Creates PR: "Dark mode: CSS token system"
   → Suggests squash merge
```

---

### Chain 4: Context Management
**Trigger:** Session ending or context window approaching limits.

```
/session-handoff
    ↓ produces HANDOVER.md with:
    ↓   - git state (branch, modified files)
    ↓   - decisions made this session
    ↓   - open questions
    ↓   - resume checklist for next session
```

---

### Chain 5: Retrospective
**Trigger:** 10 User Stories completed (counter in project memory).

```
/kaizen
    ↓ guides continuous improvement:
    ↓   - root cause analysis of recent issues
    ↓   - error proofing opportunities
    ↓   - standardization candidates
    ↓   - actionable items → BACKLOG#Ideation or CLAUDE.md rule updates
```

---

## Skills by Category

### Dev Loop Skills (wired to inner loop steps)

| Skill | Step | What It Does | When to Skip |
|-------|------|-------------|--------------|
| `/test-driven-development` | 6 | Writes failing test before implementation | Non-US tasks (spikes, docs) |
| `/verification-before-completion` | 7 | Verifies acceptance criteria with evidence | Never — always required |
| `/requesting-code-review` | 8 | Self-reviews changed files for issues | Trivial 1-line fixes |
| `/receiving-code-review` | 8 | Evaluates and applies review feedback | No feedback to process |
| `/production-code-audit` | 9 | Deep security/perf/arch scan | Tasks sized S (Small) |
| `/clean-code` | 9 | Coding standards during cleanup fixes | N/A (enforced by /sc:cleanup) |
| `/commit-smart` | 10 | Semantic conventional commit with context | Never — always required |
| `/finishing-a-development-branch` | 11 | PR creation, branch cleanup, merge | Not on a feature branch |
| `/session-handoff` | 13 | Context save for next session | Never — always at session end |
| `/kaizen` | retro | Continuous improvement retrospective | Counter < 10 stories |

---

### Support Process Skills (parallel to dev loop)

#### SP-1: Go-to-Market Pipeline

**Trigger:** New product/feature release, marketplace listing.
**Cadence:** Per release.
**Owner:** Human initiates, agent executes.

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `/marketing-strategy-pmm` | Positioning, ICP definition, messaging framework |
| 2 | `/launch-strategy` | Launch plan, timeline, channel selection |
| 3+ | `/executing-marketing-campaigns` | Campaign execution across channels |
| 3+ | `/copywriting` | Landing page, listing, ad copy |
| 3+ | `/copy-editing` | Polish and refine existing copy |
| 3+ | `/social-content` | Platform-specific social media content |
| 3+ | `/marketing-ideas` | Brainstorm campaign concepts |

**Feedback loop:** Campaign metrics → BACKLOG#Ideation for product improvements.

---

#### SP-2: SEO & Discovery Engine

**Trigger:** Monthly audit cycle or new content published.
**Cadence:** Monthly audit + per-listing optimization.
**Owner:** Human initiates audit, agent runs optimization.

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `/seo-audit` | Technical SEO health check |
| 2 | `/seo-optimizer` | Content and keyword optimization |
| 2 | `/programmatic-seo` | Template-driven pages at scale |
| 2 | `/schema-markup` | Structured data for rich results |
| 2 | `/analytics-tracking` | Event tracking setup |
| 3 | `/google-analytics` | Traffic analysis and insights |
| 3 | `/roier-seo` | Lighthouse/PageSpeed performance audit |

**Feedback loop:** SEO findings → BACKLOG#Ideation for technical fixes.

---

#### SP-3: Competitive Intelligence Radar

**Trigger:** Planning round, new competitor detected, quarterly review.
**Cadence:** Per planning round or quarterly.
**Owner:** Human initiates, agent researches.

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `/competitor-alternatives` | Competitor comparison and mapping |
| 2 | `/pricing-strategy` | Pricing model analysis and recommendations |
| 3 | `/free-tool-strategy` | Free tool as marketing/acquisition lever |
| 4 | `/x-twitter-scraper` | Social signal and trend monitoring |
| 5 | `/app-store-optimization` | Marketplace listing optimization |

**Feedback loop:** Competitive insights → BACKLOG priorities, pricing adjustments.

---

#### SP-4: Content Production Desk

**Trigger:** New listing needed, content calendar slot.
**Cadence:** Per listing or weekly.
**Owner:** Human assigns topic, agent produces.

| Step | Skill | Purpose |
|------|-------|---------|
| 1 | `/content-research-writer` | Research-backed articles with citations |
| 2 | `/content-creator` | SEO-optimized marketing content |
| 3 | `/copy-editing` | Final polish pass |
| 4 | `/viral-generator-builder` | Shareable interactive tools |
| 5 | `/shopify-development` | E-commerce integration |

**Feedback loop:** Content performance → BACKLOG#Ideation for new topics.

---

### On-Demand Toolbox (invoke as needed)

| Skill | Category | Use When |
|-------|----------|----------|
| `/sh:ux-design` | Design | Clickable wireframe prototypes — validate flow before hi-fi |
| `/figma` | Design | Translating Figma designs into code |
| `/frontend-design` | Design | Building production-grade UI from scratch (or graduating a wireframe) |
| `/canvas-design` | Design | Creating visual artifacts (PNG, PDF) |
| `/imagegen` | Generation | Generating or editing images via AI |
| `/algorithmic-art` | Generation | Creating generative art with p5.js |
| `/excalidraw-diagram` | Visualization | Visualizing workflows, architectures, data flows |
| `/theme-factory` | Styling | Applying themed templates to artifacts |
| `/git-pushing` | Git | Safe push with pre-flight checks |
| `/using-git-worktrees` | Git | Isolated feature work in git worktrees |
| `/git-context-controller` | Git | Managing agent memory as versioned files |
| `/web-performance-optimization` | Performance | Core Web Vitals, bundle size, caching |

---

### Utility Skills (available but not governance-wired)

These skills are useful but don't have a fixed position in the loop. Invoke them when the context calls for it.

| Skill | Purpose |
|-------|---------|
| `/changelog-generator` | Auto-generate changelogs from git history |
| `/clean-code` | Pragmatic coding standards reference |
| `/code-review-checklist` | Comprehensive review checklist template |
| `/crafting-effective-readmes` | README authoring by audience type |
| `/create-plan` | Concise implementation plan for coding tasks |
| `/doc-coauthoring` | Structured documentation co-authoring workflow |
| `/executing-plans` | Execute written plans with review checkpoints |
| `/planning-with-files` | Manus-style file-based planning (task_plan.md, findings.md) |
| `/python-patterns` | Python development principles and decision-making |
| `/reducing-entropy` | Minimize total codebase size (manual activation only) |
| `/security-best-practices` | Language/framework-specific security review |
| `/security-threat-model` | Repository-grounded threat modeling |
| `/ship-learn-next` | Transform learning content into implementation plans |
| `/skill-creator` | Guide for creating new skills |
| `/software-architecture` | Python/FastAPI architecture patterns |
| `/writing-plans` | Plan implementation strategy before coding |
| `/writing-rules` | Create hookify rules for automation |

---

## Quick Reference: "Which skill do I need?"

| I want to... | Use this skill |
|--------------|---------------|
| Turn a raw idea into a spec | `/sc:brainstorm` → `/requirements-clarity` → `/sc:spec-panel` |
| Start implementing a feature | `/test-driven-development` |
| Check if my work is really done | `/verification-before-completion` |
| Review my own code | `/requesting-code-review` |
| Respond to review feedback | `/receiving-code-review` |
| Run a quality check | `/sc:analyze` → `/sc:cleanup` |
| Do a deep security/perf audit | `/production-code-audit` |
| Make a good commit | `/commit-smart` |
| Create a PR and clean up branch | `/finishing-a-development-branch` |
| Save context for next session | `/session-handoff` |
| Run a team retrospective | `/kaizen` |
| Write marketing copy | `/copywriting` or `/copy-editing` |
| Optimize for search engines | `/seo-audit` → `/seo-optimizer` |
| Analyze competitors | `/competitor-alternatives` → `/pricing-strategy` |
| Create visual content | `/canvas-design` or `/imagegen` |
| Wireframe a user flow | `/sh:ux-design` → `/frontend-design` |
| Build a UI component | `/frontend-design` or `/figma` |
| Plan before coding | `/create-plan` or `/writing-plans` |
| Create a new skill | `/skill-creator` |

---

_61 skills wired to governance. 17 utility skills available on demand. Zero orphans._
