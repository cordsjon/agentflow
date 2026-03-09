# Agent Capabilities — Routing Manifest

> **Used by:** ORCHESTRATOR.md routing logic.
> **Updated:** During planning rounds, after retros, or when agent capabilities change.

---

## Capability Schema

Each agent entry follows this structure:

```
## Agent Name (@handle)
- **Status:** active | stub | planned
- **Transport:** How the agent connects (MCP, Tether, HTTP, Sheets, manual relay)
- **Strengths:** Keyword list — matched against task descriptions for routing
- **Context access:** What repos/files/APIs the agent can read/write
- **Constraints:** Hard limits that disqualify the agent from certain tasks
- **Historical:** Observed performance patterns (updated after retros)
- **Routing weight:** Base multiplier (0.0–1.0) applied to all scores
```

---

## Claude Code (@claude)

- **Status:** active
- **Transport:** Native CLI — direct repo access, MCP tools, file I/O
- **Strengths:**
  - implementation, refactoring, code review, test writing
  - SVG generation, contrast calculation, export pipeline
  - database migrations, Alembic, SQLModel, SQLite
  - FastAPI routes, Jinja2 templates, vanilla JS
  - bug diagnosis, root cause analysis, crash triage
  - git operations, commit formatting, branch management
  - documentation updates (KNOWN_PATTERNS, QUALITY_AUDIT, MEMORY)
  - PowerShell scripting (with ASCII-only constraint)
  - CI/CD pipeline, build scripts, deployment
  - architecture design, spec review, API contract design
  - greenlight protocol, quality audit, cleanup passes
- **Context access:**
  - Full read/write: all project repos (SVG-PAINT, Tether, Governance, Whitelabel)
  - vexp index: pre-indexed codebase graph (5280 nodes, 6922 edges)
  - GitNexus: symbol-level code intelligence (6779 nodes, 18783 edges)
  - MCP servers: Tether, Context7, Mermaid, Figma, Notion, Linear, HF, MS Learn
  - File system: full local access
  - Git: full read/write
- **Constraints:**
  - Single-threaded execution (one task at a time)
  - Windows 10 environment (PowerShell 5.1 quirks)
  - No internet browsing without WebFetch/WebSearch tools
  - Context window limit (managed by compression, but deep tasks may need chunking)
- **Historical:**
  - 92 endpoints implemented in Phase 1a (zero regressions)
  - 1249 tests written (all passing)
  - 694 quality findings resolved across 19 audit passes
  - Strong on implementation + test cycles
  - Occasionally over-engineers when scope is ambiguous — benefits from tight AC
- **Routing weight:** 1.0

---

## Gemini (@gemini)

- **Status:** stub
- **Transport:** Google Sheets bridge (via Tether HTTP API + ngrok + AppScript) | HTTP API relay
- **Strengths:**
  - research, competitive analysis, market research
  - large-context document analysis (1M+ token window)
  - spec review, requirements critique (external perspective)
  - Etsy listing optimization, SEO analysis
  - trend analysis, keyword research
  - summarization of long documents
  - brainstorming, ideation expansion
- **Context access:**
  - Read-only: Tether messages via Google Sheets (auto-refresh 2min)
  - Read-only: Tether HTTP API (if ngrok tunnel active)
  - No direct repo access — requires context to be sent via Tether or pasted
  - Google Workspace: Sheets, Docs (native)
  - Web search: native
- **Constraints:**
  - No repo write access — cannot implement code directly
  - All outputs must be relayed back via Tether or manual copy
  - Latency: ~2min via Sheets polling, real-time via HTTP
  - No MCP client support yet (Gemini side)
  - Session continuity: no persistent memory across sessions without Tether
- **Historical:**
  - First contact via Sheets bridge: 2026-03-01
  - No task routing yet — stub only
- **Routing weight:** 0.0 _(stub — set to 0.5+ when activated)_

---

## ChatGPT (@chatgpt)

- **Status:** stub
- **Transport:** Google Sheets bridge | HTTP API relay | manual paste
- **Strengths:**
  - copywriting, user-facing documentation
  - marketing copy, product descriptions
  - Etsy listing titles, tags, descriptions
  - educational content, help guides
  - conversational UX copy
  - translation, localization
- **Context access:**
  - Read-only: Tether messages via Google Sheets (shared)
  - No direct repo access
  - Web browsing: native (with browsing enabled)
  - DALL-E: image generation (if needed for mockups)
- **Constraints:**
  - No repo write access
  - All outputs relayed via Tether or manual
  - No MCP client support
  - No persistent memory across sessions without Tether
  - Rate limits on GPT-4 tier
- **Historical:**
  - No first contact yet
  - No task routing yet — stub only
- **Routing weight:** 0.0 _(stub — set to 0.5+ when activated)_

---

## Grok (@grok)

- **Status:** stub
- **Transport:** Google Sheets bridge | HTTP API relay | manual paste
- **Strengths:**
  - real-time information, current events context
  - X/Twitter trend analysis
  - technical Q&A with current data
  - code review (secondary opinion)
- **Context access:**
  - Read-only: Tether messages via Google Sheets (shared)
  - No direct repo access
  - Real-time web: native (X integration)
- **Constraints:**
  - No repo write access
  - All outputs relayed via Tether or manual
  - No MCP client support
  - Limited availability (xAI API access)
- **Historical:**
  - No first contact yet
  - No task routing yet — stub only
- **Routing weight:** 0.0 _(stub — set to 0.5+ when activated)_

---

## Activation Checklist (stub → active)

When bringing a stub agent online:

1. [ ] **Transport verified** — Agent can receive messages (Tether inbox check)
2. [ ] **First contact completed** — Successful round-trip message via Tether
3. [ ] **Kilo Bootstrap sent** — Agent received and acknowledged cold-start protocol
4. [ ] **Test task completed** — One low-risk task routed and result validated
5. [ ] **Routing weight set** — Update from 0.0 to appropriate weight (0.5 for limited, 0.8 for capable, 1.0 for full)
6. [ ] **Historical baseline** — First 3 tasks documented with outcome
7. [ ] **Constraints validated** — Confirmed what the agent can/cannot do in practice

---

## Routing Examples

### Example 1: Implementation task
```
Task: "implement FE-32 font preview refresh"
Keywords: implement, font, preview, frontend

@claude:   implement(+1) font(+1) preview(+1) + repo_access(+2) = 5
@gemini:   0 matches + no_repo(-10) = -10
@chatgpt:  0 matches + no_repo(-10) = -10

Route: @claude (confidence: 1.0)
```

### Example 2: Research task
```
Task: "research Etsy SEO trends for contrast card listings"
Keywords: research, Etsy, SEO, trends, listings

@claude:   0 matches + no_web_browsing(-2) = -2
@gemini:   research(+1) Etsy(+1) SEO(+1) trends(+1) + web_search(+2) = 6
@chatgpt:  Etsy(+1) listings(+1) + web_browsing(+2) = 4

Route: @gemini (confidence: 0.75) — requires stub activation first
Fallback: @claude with WebSearch tool (confidence: 0.5)
```

### Example 3: Copywriting task
```
Task: "write help guide for the export workflow"
Keywords: write, help, guide, documentation

@claude:   documentation(+1) + repo_access(+2) = 3
@chatgpt:  copywriting(+1) documentation(+1) help(+1) guide(+1) = 4
@gemini:   summarization(+1) = 1

Route: @chatgpt (confidence: 0.65) — requires stub activation first
Fallback: @claude (confidence: 0.6)
```

---

## Maintenance

- **Planning rounds:** Review routing weights and historical performance
- **After retros:** Update strengths/constraints based on observed behavior
- **On agent activation:** Fill in Historical section, set routing weight
- **On new MCP/transport:** Update Transport and Context access sections
