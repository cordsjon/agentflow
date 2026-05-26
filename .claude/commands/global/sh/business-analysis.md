---
name: business-analysis
description: "Interactive business analysis workbench — pick frameworks by number (SWOT, BMC, Five Forces, PESTLE, etc.), get text analysis first, then optionally render as DIN poster PDF"
argument-hint: "<topic_or_document> [context notes]"
---

# /sh:business-analysis — Business Analysis Workbench

## Purpose

Interactive business analysis tool. When invoked, presents a numbered menu of analytical frameworks. The user picks which to run by number. Each selected framework produces **structured text analysis first**. A poster PDF is an optional final step, not the default.

## Step 1: Present the Menu

When the skill is invoked, **immediately** display this menu (do NOT skip it):

```
BUSINESS ANALYSIS WORKBENCH
============================
Topic: <topic from user input>

Pick analyses by number. Combine freely.
Example: "Do 1, 4, 11 for <topic>" or "All strategic" or "Just 7"

--- STRATEGIC ANALYSIS ---
 1. SWOT Analysis          — Strengths, Weaknesses, Opportunities, Threats
 2. PESTLE Analysis        — Political, Economic, Social, Tech, Legal, Environmental
 3. Porter's Five Forces   — Competitive pressure mapping
 4. Business Model Canvas  — 9-block: partners, activities, value prop, segments, revenue
 5. Value Chain Analysis   — Where value is created/lost across primary & support activities

--- REQUIREMENTS & PRIORITIZATION ---
 6. MoSCoW Prioritization  — Must / Should / Could / Won't
 7. User Story Map         — Journey steps × release prioritization
 8. Gap Analysis           — Current state vs desired state + action items

--- PROBLEM DIAGNOSIS ---
 9. Fishbone (Ishikawa)    — Root cause analysis by category
10. 5 Whys Deep Dive       — Iterative "why?" to find root cause of a specific problem
11. Pareto Analysis        — Which 20% of causes drive 80% of impact

--- RISK & DECISION ---
12. Risk Matrix            — 5×5 likelihood × impact heatmap
13. Decision Matrix        — Weighted multi-criteria scoring for option comparison
14. Feasibility Study      — Technical, operational, financial, schedule viability
15. Cost-Benefit Analysis  — Quantified ROI with payback period

--- ROLES & GOVERNANCE ---
16. RACI Matrix            — Responsible, Accountable, Consulted, Informed per task
17. Stakeholder Map        — Influence × interest grid with engagement strategy

--- METRICS & TRACKING ---
18. KPI Definition         — Leading & lagging indicators with targets and baselines
19. Benchmarking           — Compare against industry standards or competitors

--- TECHNICAL ---
20. Solution Architecture  — Pipeline steps, components, data flow
21. Technology Stack       — Component cards with rationale
22. Regulatory Constraints — Law × constraint × severity × impact table
23. Evolution Roadmap      — Phased timeline with milestones

--- CHANGE & DELIVERY ---
24. Impact Analysis        — Who/what is affected by the proposed change
25. Traceability Matrix    — Requirements → design → test → delivery mapping
26. Acceptance Criteria    — Definition of done per requirement
27. UAT Plan              — Structured user validation before go-live

--- OUTPUT ---
28. Generate Poster PDF    — Render completed analyses as DIN A1/A0/A2 poster
29. Export Markdown Report — Save all analyses to a single .md file
30. Export JSON Data       — Save structured data for reuse / poster regeneration

Shortcuts:
  "all strategic"     → 1-5
  "all requirements"  → 6-8
  "all risk"          → 12-15
  "all technical"     → 20-23
  "full assessment"   → 1, 2, 3, 6, 12, 16, 18, 20
```

Then **wait for the user to pick**. Do NOT auto-select. Do NOT start analyzing.

## Step 2: Run Selected Analyses (Text Output)

For each selected number, produce a **structured text analysis** in conversation. Research the topic first (read documents, search if needed), then output each analysis as a clearly formatted section.

### Output Format Per Analysis

Use this structure for each:

```
## [N]. Framework Name
### Context
<1-2 sentences: why this framework matters for this topic>

### Analysis
<The actual framework output — tables, grids, lists as appropriate>

### Key Takeaways
- <Insight 1>
- <Insight 2>
- <Insight 3>
```

### Framework-Specific Output Formats

**1. SWOT** — 2×2 table: Strengths | Weaknesses | Opportunities | Threats (3-5 items each)

**2. PESTLE** — 6 categories, 2-4 factors each with impact rating (High/Med/Low)

**3. Five Forces** — 5 forces with pressure rating (Strong/Moderate/Weak) + supporting evidence

**4. BMC** — 9 blocks: Key Partners, Key Activities, Key Resources, Value Propositions, Customer Relationships, Channels, Customer Segments, Cost Structure, Revenue Streams

**5. Value Chain** — Primary activities (Inbound → Operations → Outbound → Marketing → Service) + Support activities (Infrastructure, HR, Technology, Procurement). Mark where value is created vs lost.

**6. MoSCoW** — 4 columns with items. Must items get brief justification.

**7. Story Map** — Journey steps across the top, activities stacked per step, release lines drawn

**8. Gap Analysis** — Current State | Desired State | Gap | Action — as a table

**9. Fishbone** — Effect statement + 4-6 cause categories (People, Process, Technology, Data, Environment, Management) with 2-4 causes each

**10. 5 Whys** — State the problem, then 5 iterative "Why?" questions with answers, arriving at root cause

**11. Pareto** — Ranked list of causes with cumulative %, mark the 80% line

**12. Risk Matrix** — Table: Risk | Likelihood (1-5) | Impact (1-5) | Score | Mitigation. Sort by score descending.

**13. Decision Matrix** — Table: Option × Criteria (weighted). Show scores and winner.

**14. Feasibility Study** — 4 dimensions (Technical, Operational, Financial, Schedule) rated Green/Amber/Red with evidence

**15. Cost-Benefit** — Costs table + Benefits table + Net present value / payback period

**16. RACI** — Grid: Tasks × Roles with R/A/C/I assignments

**17. Stakeholder Map** — Table: Stakeholder | Influence (H/M/L) | Interest (H/M/L) | Strategy (Manage Closely / Keep Satisfied / Keep Informed / Monitor)

**18. KPI Definition** — Table: KPI | Type (Leading/Lagging) | Current | Target | Measurement Frequency

**19. Benchmarking** — Table: Metric | Our Value | Industry Average | Best in Class | Gap

**20. Solution Architecture** — Numbered pipeline: Step → Tool/Technology → Description → Data flow

**21. Technology Stack** — Cards: Component | Purpose | Rationale | Alternatives Considered

**22. Regulatory Constraints** — Table: Law/Regulation | Constraint | Severity | Rule | Impact on Solution

**23. Evolution Roadmap** — Phase cards: Phase N | Name | Timeline | Key Deliverables | Dependencies

**24. Impact Analysis** — Table: Area Affected | Current State | Change | Impact Level | Mitigation

**25. Traceability Matrix** — Table: Requirement ID | Requirement | Design Component | Test Case | Status

**26. Acceptance Criteria** — Per requirement: Given/When/Then format or checklist

**27. UAT Plan** — Table: Test Scenario | Test Steps | Expected Result | Tester | Status

## Step 3: After All Analyses Complete

Present a summary:

```
ANALYSIS COMPLETE
==================
Completed: [list of analyses run]
Key findings across all analyses:
  1. <Cross-cutting insight>
  2. <Cross-cutting insight>
  3. <Cross-cutting insight>

Next steps:
  - Pick more analyses from the menu (give numbers)
  - "28" → Generate poster PDF from these results
  - "29" → Export as markdown report
  - "30" → Export as JSON data
  - Ask follow-up questions about any analysis
```

## Step 4: Poster Generation (Only When #28 Selected)

When the user selects 28 (or says "poster", "generate poster", etc.):

### Pre-flight
1. Verify reportlab: `python3 -c "import reportlab; print(reportlab.Version)"` — install if missing
2. Locate template: `~/projects/20_agentflow/tools/poster-generator/poster_template.py`

### Build poster-data.json
Convert ALL completed text analyses into the structured JSON format. Map each analysis to its `PosterCanvas` method:

| Analysis | JSON section type | PosterCanvas method |
|----------|------------------|-------------------|
| SWOT | `swot` | `swot_grid()` |
| PESTLE | `pestle` | `pestle_grid()` |
| Five Forces | `five_forces` | `five_forces()` |
| BMC | `bmc` | `bmc_grid()` |
| Value Chain | `value_chain` | `value_chain()` |
| MoSCoW | `moscow` | `moscow_columns()` |
| Story Map | `story_map` | `story_map()` |
| Gap Analysis | `gap` | `gap_panel()` |
| Fishbone | `fishbone` | `fishbone()` |
| Risk Matrix | `risk_matrix` | `risk_matrix()` |
| Decision Matrix | `decision_matrix` | `decision_matrix()` |
| RACI | `raci` | `raci_matrix()` |
| KPI | `kpi` | `kpi_card()` |
| Architecture | `pipeline` | `pipeline_step()` |
| Tech Stack | `cards` | cards layout |
| Regulatory | `table` | `table_header()` + `table_row()` |
| Roadmap | `phases` | `phase_card()` |
| Stakeholder Map | `table` | `table_header()` + `table_row()` |

Analyses without a direct PosterCanvas mapping (5 Whys, Pareto, Feasibility, CBA, Impact, Traceability, Acceptance Criteria, UAT Plan, Benchmarking) render as **tables** or **callout boxes**.

### JSON Schema

```json
{
  "title": "Poster Title",
  "subtitle": "Domain description",
  "format": "A1",
  "style": "dark",
  "badges": [["LABEL", "bg_color", "fg_color"]],
  "footer": {"left": "Author / date", "right": "Version"},
  "sections": [ ]
}
```

Each section follows the type-specific schema. See the PosterCanvas method signatures in `poster_template.py` for field names.

### Layout Rules
- **Column count adapts**: 1-2 sections = full width, 3-4 = 2 columns, 5+ = 3 columns
- **Large frameworks** (BMC, Five Forces, Value Chain, Fishbone, Story Map) get at least half poster width
- **Compact frameworks** (SWOT, MoSCoW, Gap, KPI) share columns
- **Tables** (Regulatory, RACI, Decision Matrix) span full width
- **Fill the page**: Content within 15mm of all edges. Empty space = defect.
- **Font sizes for A1**: Titles 28-32pt, headers 14-16pt, body 7-9pt, tables 6-7.5pt
- Use `python3` (never hardcode a path)

### Generate & Verify
1. Write generator script that reads `poster-data.json` and uses `PosterCanvas`
2. Run: `python3 generate_poster.py`
3. Verify output >10KB
4. Visual check for overflow/overlap/empty space — fix and re-run up to 3 times

### Deliverables
- The PDF poster
- `poster-data.json`
- The generator script

## Template Reference

**Primary template**: `~/projects/20_agentflow/tools/poster-generator/poster_template.py`

Do NOT use `generate_poster.py` — it is a domain-specific example, not a reusable reference.

## Integration with /sh:business-panel

`/sh:business-panel` output can inform analysis. If the user mentions panel output, parse it for expert perspectives and use as research input for Step 2.

## Examples

```
# Opens the menu, user picks from there
/sh:business-analysis "AI adoption in German tax advisory"

# With a document as context
/sh:business-analysis docs/business-plan.md

# User response examples after seeing menu:
"Do 1, 3, 4"                          → SWOT + Five Forces + BMC
"All strategic for KETO app"           → 1-5
"12 and 13 comparing React vs Flutter" → Risk Matrix + Decision Matrix
"Full assessment"                      → 1, 2, 3, 6, 12, 16, 18, 20
"Do 9 for high customer churn"         → Fishbone on churn
"Now do 28"                            → Generate poster from completed analyses
```
