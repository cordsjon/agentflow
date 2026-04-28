---
name: sh:design-panel
description: "Multi-expert UX/UI/Digital Design review panel with tool-augmented evidence, scoring gate, and generative alternatives. Use when reviewing UI designs, Figma files, live URLs, or any user-facing interface for usability, accessibility, visual quality, and design system coherence."
needs: [code-context?, doc-lookup?, web-research?]
---

# /sh:design-panel — Expert UX/UI/Digital Design Review Panel

## Usage

```
/sh:design-panel [design_content|@file|URL|figma_url] [--mode discussion|critique|socratic|generative] [--evidence passive|active] [--focus ux-research|visual-design|interaction-design|accessibility|design-systems|content-strategy|mobile-first|design-to-code] [--experts "name1,name2"] [--iterations N] [--verbose]
```

## Verbosity

- **Silent (default)**: No expert deliberations. Output only: score table, FIPD-classified findings list, and auto-fix diff. Saves ~60-80% output tokens.
- **Verbose (`--verbose`)**: Full expert deliberations, cross-expert dialogue, reasoning traces, and detailed per-expert analysis before scores and findings.

Silent mode still performs full internal analysis — quality is preserved, only the output is compressed.

## Behavioral Flow

1. **Detect Input**: Auto-detect input type — Figma URL → Figma MCP, live URL → Playwright, Canva URL → Canva MCP, image → multimodal Read, text → direct analysis
2. **Analyze**: Identify design type (dashboard, form, onboarding, landing page, mobile app) and surface issues
3. **Assemble Panel**: Select experts based on `--focus` area or use defaults. `--experts` override replaces defaults entirely. Max 6 experts per review.
4. **Conduct Review**: Run analysis in selected mode using each expert's distinct methodology
5. **Gather Evidence** (if `--evidence active`): Experts call MCP tools to verify claims before stating them
6. **Generate Alternatives** (if `--mode generative`): Experts produce visual alternatives via alphabanana/Stitch
7. **Score**: Rate design across 5 dimensions (0-10 each), compute overall score
8. **Gate Check**: Overall score must be >= 7.0 to pass. Below threshold = design needs rework

## Expert Panel (14 experts)

| Category | Expert | Domain |
|---|---|---|
| UX Research | Don Norman | Affordances, cognitive load, conceptual models, 7 stages of action |
| UX Research | Jared Spool | UX strategy, design maturity, research-driven design |
| UX Research | Indi Young | Mental models, problem space, deep listening, inclusive framing |
| Visual Design | Josef Müller-Brockmann | Grid systems, typographic hierarchy, Swiss design principles |
| Visual Design | Dieter Rams | 10 Principles of Good Design, functional aesthetics, restraint |
| Visual Design | Mike Monteiro | Design ethics, dark pattern detection, designer responsibility |
| Interaction | Alan Cooper | Goal-directed design, personas (inventor), interaction patterns |
| Interaction | Luke Wroblewski | Mobile-first, form design, touch targets, data-informed design |
| Interaction | Brad Frost | Atomic Design, design systems, component-driven design |
| Accessibility | Heydon Pickering | Inclusive patterns, ARIA, keyboard nav, screen reader compat |
| Accessibility | Sara Soueidan | WCAG 2.2, semantic HTML, contrast, focus management, SVG a11y |
| Content & IA | Steve Krug | Usability testing, "Don't Make Me Think", trunk test, simplicity |
| Content & IA | Kim Lauenroth | IREB Digital Design, user journeys, experience-first specification |
| Generative UI | Yaniv Leviathan | AI-native UI generation, PAGEN baseline, ELO-based evaluation |

## Analysis Modes

### Discussion Mode (`--mode discussion`)
Collaborative expert dialogue. Sequential commentary building on each other's insights. Cross-expert validation and consensus building. Default mode.

### Critique Mode (`--mode critique`)
Systematic review with severity-classified issues (CRITICAL / MAJOR / MINOR). Each finding includes: expert attribution, specific recommendation, priority ranking, quality impact, and WCAG reference where applicable. Best paired with `--evidence active` for tool-verified findings.

### Socratic Mode (`--mode socratic`)
Question-driven exploration. Experts pose probing questions about users, goals, mental models, visual structure, accessibility, and journey completeness. No direct answers — forces the designer to think critically.

### Generative Mode (`--mode generative`)
Experts produce design alternatives using MCP tools — not just critique, but create. alphabanana generates mockups, Stitch generates UI alternatives, Playwright renders and screenshots results. Unique to design-panel.

## Evidence Modes

- `--evidence passive` (default): Expert opinions based on provided content only. No MCP tool calls.
- `--evidence active`: Experts call MCP tools to verify claims. Playwright for DOM/a11y audit, Figma for token extraction, etc. Produces measurement-backed findings.

## Focus Areas

- **ux-research**: Conceptual models, research evidence, mental models, goals. Lead: Don Norman. Experts: Norman, Spool, Young, Cooper
- **visual-design**: Grid, typography, color, spacing, signal-to-noise. Lead: Müller-Brockmann. Experts: Müller-Brockmann, Rams, Frost
- **interaction-design**: Goal-directed flows, forms, progressive disclosure. Lead: Alan Cooper. Experts: Cooper, Wroblewski, Krug
- **accessibility**: WCAG 2.2, keyboard nav, ARIA, contrast, focus. Lead: Heydon Pickering. Experts: Pickering, Soueidan, Krug
- **design-systems**: Atomic hierarchy, tokens, component API, adoption %. Lead: Brad Frost. Experts: Frost, Rams, Wroblewski
- **content-strategy**: Microcopy, info scent, error messages, empty states. Lead: Steve Krug. Experts: Krug, Norman, Lauenroth
- **mobile-first**: Touch targets, thumb zones, responsive, progressive enhancement. Lead: Luke Wroblewski. Experts: Wroblewski, Krug, Pickering
- **design-to-code**: Figma-to-code fidelity, Code Connect, semantic HTML, token mapping. Lead: Brad Frost. Experts: Frost, Soueidan, Wroblewski

## MCP Tools (active evidence & generative mode)

| MCP | Use |
|---|---|
| Figma | Screenshots, design tokens, Code Connect, design system rules |
| Playwright | Live URL screenshots, DOM audit, responsive testing, a11y check |
| Canva | Design content review, page analysis |
| iwdp-mcp | iOS/Safari real device testing |
| Context7 | WCAG docs, framework guidelines |
| alphabanana | Generate visual design alternatives |
| Stitch (optional) | AI-native UI generation, DESIGN.md extraction |
| Gamma (optional) | Presentation of findings |

## Scoring Gate

5 dimensions, each scored 0-10:

| Dimension | Description |
|---|---|
| Usability | Learnability, efficiency, error prevention, cognitive load |
| Consistency | Visual/interaction coherence, design system alignment |
| Accessibility | WCAG compliance, inclusive patterns, assistive tech support |
| Hierarchy | Information architecture, visual priority, content flow |
| User-Centeredness | Research grounding, persona alignment, journey completeness |

**Pass threshold: overall score >= 7.0**

Output includes per-dimension scores, overall score, critical issues, expert consensus, and improvement roadmap (immediate / short-term / long-term).

## Output

Design review document containing:
- Multi-expert analysis with distinct design perspectives
- Tool-verified evidence (when `--evidence active`)
- Per-dimension scores and overall quality score
- Pass/fail gate result
- Critical issues with severity, WCAG refs, and priority
- Visual alternatives (when `--mode generative`)
- Consensus points and disagreements
- Priority-ranked improvement recommendations

**SYNTHESIS ONLY** — this panel produces analysis, recommendations, and visual alternatives. It does not modify designs or implement changes without explicit instruction.

**Next Step**: After review, incorporate feedback into design. Use `/sc:spec-panel --focus digital-design` for specification. Use `/sc:implement` when ready to build.


## Auto-Fix Policy
Fix ALL findings automatically — high, medium, and low severity. Do not ask which findings to fix. Do not present a menu. Fix everything, then report what was changed.
