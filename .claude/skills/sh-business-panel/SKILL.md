---
name: sh:business-panel
description: "Multi-expert business analysis with advisory recommendations (no scoring gate)"
---

# /sh:business-panel — Business Panel Analysis

## Usage

```
/sh:business-panel [document_path_or_content] [--mode discussion|debate|socratic] [--focus competitive|growth|risk|communication] [--experts "name1,name2"] [--synthesis-only]
```

## Behavioral Flow

1. **Load Panel Config**: Read `experts/panels/business-panel.yaml` for panel definition, focus areas, and auto-select rules
2. **Load Experts**: Read expert files from `experts/individuals/` for each selected expert — these contain domain, methodology, and critique focus
3. **Auto-Select Experts**: Scan content against panel YAML `auto-select` keywords — add matching experts up to `max-experts: 6` cap
4. **Analyze**: Parse business content, identify strategic themes and domains
5. **Assemble Panel**: Select experts based on `--focus` area or use `default-experts`. `--experts` override replaces defaults entirely
6. **Conduct Analysis**: Run analysis in the selected mode using each expert's distinct framework
7. **Synthesize**: Generate consolidated findings with consensus, disagreements, and prioritized recommendations

**No scoring gate** — this is an advisory panel. It produces strategic analysis and recommendations only.

## Expert Panel (9 experts from core-business pack)

| Expert                         | Domain                                      |
|--------------------------------|---------------------------------------------|
| Clayton Christensen            | Disruption Theory, Jobs-to-be-Done          |
| Michael Porter                 | Competitive Strategy, Five Forces            |
| Peter Drucker                  | Management Philosophy, MBO                   |
| Seth Godin                     | Marketing Innovation, Tribe Building         |
| W. Chan Kim & Renee Mauborgne | Blue Ocean Strategy                          |
| Jim Collins                    | Organizational Excellence, Good to Great     |
| Nassim Nicholas Taleb          | Risk Management, Antifragility               |
| Donella Meadows                | Systems Thinking, Leverage Points            |
| Jean-luc Doumont               | Communication Systems, Structured Clarity    |

## Analysis Modes

### Discussion Mode (`--mode discussion`)
Collaborative analysis where experts build upon each other's insights through their frameworks. Default mode. Sequential commentary, cross-expert validation, consensus building.

### Debate Mode (`--mode debate`)
Adversarial analysis for stress-testing ideas. Experts challenge each other's positions, surface disagreements, and argue alternatives. Use for controversial topics or high-stakes decisions.

### Socratic Mode (`--mode socratic`)
Question-driven exploration for deep strategic thinking. Experts pose probing questions rather than giving answers. Forces deeper examination of assumptions and alternatives.

## Focus Areas

- **competitive**: Competitive positioning, market forces, strategy. Lead: Michael Porter. Experts: Porter, Christensen, Kim & Mauborgne
- **growth**: Marketing, tribe building, scaling. Lead: Seth Godin. Experts: Godin, Collins, Drucker
- **risk**: Risk management, antifragility, systems dynamics. Lead: Nassim Taleb. Experts: Taleb, Meadows
- **communication**: Structured clarity, presentation, stakeholder messaging. Lead: Jean-luc Doumont. Experts: Doumont, Godin

## Output

Business analysis document containing:
- Expert perspectives from selected panelists
- Consensus points across experts
- Disagreements with reasoning from each side
- Priority-ranked strategic recommendations
- Actionable next steps

**SYNTHESIS ONLY** — this panel produces expert analysis and recommendations. It does not implement any business recommendations, make code changes, or execute decisions without explicit user approval.
