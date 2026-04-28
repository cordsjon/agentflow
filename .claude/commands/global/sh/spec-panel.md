---
name: sh-spec-panel
description: "Use when a spec or User Story needs a quality gate before implementation — required when spec-panel score >= 7.0 is a DOR criterion"
---

# /sh:spec-panel — Expert Specification Review Panel

## Usage

```
/sh:spec-panel [specification_content|@file] [--mode discussion|critique|socratic] [--focus requirements|architecture|testing|compliance] [--experts "name1,name2"] [--iterations N]
```

## Behavioral Flow

1. **Load Panel Config**: Read `experts/panels/spec-panel.yaml` for panel definition, focus areas, auto-select rules, and scoring config
2. **Load Experts**: Read expert files from `experts/individuals/` for each selected expert — these files contain the expert's domain, methodology, and critique focus
3. **Auto-Select Experts**: Scan the specification content against panel YAML `auto-select` keywords — add matching experts up to `max-experts: 6` cap
4. **Analyze**: Parse specification content, identify components, gaps, and quality issues
5. **Assemble Panel**: Select experts based on `--focus` area or use `default-experts` from panel YAML. `--experts` override replaces defaults entirely
6. **Conduct Review**: Run analysis in the selected mode using each expert's distinct methodology
7. **Score**: Rate specification across 4 dimensions (0-10 each), compute overall score
8. **Gate Check**: Overall score must be >= 7.0 to pass. Below threshold = specification needs rework

## Expert Loading

Experts are defined as individual markdown files in `experts/individuals/`. Each file contains structured frontmatter with:
- Domain and specialization
- Methodology and frameworks
- Critique focus and typical questions

The panel YAML (`experts/panels/spec-panel.yaml`) defines:
- Which experts belong to which focus area
- Who leads each focus area
- Auto-select keyword rules for dynamic expert addition
- Scoring dimensions and pass threshold

## Analysis Modes

### Discussion Mode (`--mode discussion`)
Collaborative improvement through expert dialogue. Experts build upon each other's insights sequentially. Cross-expert validation and consensus building around critical improvements.

### Critique Mode (`--mode critique`)
Systematic review with severity-classified issues (CRITICAL / MAJOR / MINOR). Each finding includes: expert attribution, specific recommendation, priority ranking, and quality impact estimate.

### Socratic Mode (`--mode socratic`)
Learning-focused questioning to deepen understanding. Experts pose foundational questions about purpose, stakeholders, assumptions, and alternatives. No direct answers — forces the author to think critically.

## Focus Areas

- **requirements**: Requirement clarity, completeness, testability. Lead: Karl Wiegers. Experts: Wiegers, Adzic, Cockburn
- **architecture**: Interface design, boundaries, scalability, patterns. Lead: Martin Fowler. Experts: Fowler, Newman, Hohpe, Nygard
- **testing**: Test strategy, coverage, edge cases, acceptance criteria. Lead: Lisa Crispin. Experts: Crispin, Gregory, Adzic
- **compliance**: Regulatory coverage, security, operational requirements. Lead: Karl Wiegers. Experts: Wiegers, Nygard, Hightower

## Scoring Gate

4 dimensions, each scored 0-10:

| Dimension     | Description                                    |
|---------------|------------------------------------------------|
| Clarity       | Language precision and understandability        |
| Completeness  | Coverage of essential specification elements   |
| Testability   | Measurability and validation capability        |
| Consistency   | Internal coherence and contradiction detection |

**Pass threshold: overall score >= 7.0**

Output includes per-dimension scores, overall score, critical issues, expert consensus points, and an improvement roadmap (immediate / short-term / long-term).

## Output

Specification review document containing:
- Multi-expert analysis with distinct perspectives
- Per-dimension scores and overall quality score
- Pass/fail gate result
- Critical issues with severity and priority
- Consensus points and disagreements
- Priority-ranked improvement recommendations

**SYNTHESIS ONLY** — this panel produces analysis and recommendations. It does not modify the specification without explicit instruction.
