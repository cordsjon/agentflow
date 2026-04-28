---
name: sh:ai-panel
description: "Multi-expert LLM/AI strategy panel with Claude Code + VS Code + macOS workflow optimization, scoring gate, and cost-quality analysis. Use when making AI tool decisions, model selection, prompt engineering, agent architecture, or Claude Code workflow optimization."
needs: [code-context?, doc-lookup?]
---

# /sh:ai-panel — Expert LLM/AI Strategy & Workflow Panel

## Usage

```
/sh:ai-panel [ai_question|@file|@prompt] [--mode discussion|critique|socratic] [--evidence passive|active] [--focus model-selection|prompt-engineering|rag-architecture|agent-design|evaluation|cost-optimization|claude-code-workflow|mcp-tooling] [--experts "name1,name2"] [--iterations N] [--verbose]
```

## Primary Context: Claude Code + VS Code + macOS

All expert advice is biased toward this stack:
- **Claude Code** (Opus/Sonnet/Haiku tiers, skills, hooks, plugins, subagents, MCP servers)
- **VS Code** (extensions, keybindings, panel workflow, integrated terminal)
- **macOS** (Homebrew, native tools, shell integration, Keychain, Shortcuts)
- **MCP servers** as the tool ecosystem
- **Skills & hooks** as the automation layer

## Verbosity

- **Silent (default)**: No expert deliberations. Output only: score table, FIPD-classified findings list, and auto-fix diff. Saves ~60-80% output tokens.
- **Verbose (`--verbose`)**: Full expert deliberations, cross-expert dialogue, reasoning traces, and detailed per-expert analysis before scores and findings.

Silent mode still performs full internal analysis — quality is preserved, only the output is compressed.

## Behavioral Flow

1. **Ingest**: Parse input — detect prompts, CLAUDE.md, settings.json, skill files, agent configs, or strategy questions
2. **Classify**: Identify AI domain (model selection, prompt design, workflow, evaluation) and complexity
3. **Assemble Panel**: Select experts based on `--focus` area or use defaults. Max 6 experts per review.
4. **Conduct Review**: Run analysis in selected mode using each expert's distinct methodology
5. **Gather Evidence** (if `--evidence active`): Experts inspect CLAUDE.md, settings, skills, hooks, MCP configs
6. **Score**: Rate AI strategy across 5 dimensions (0-10 each), compute overall score
7. **Gate Check**: Overall score must be >= 7.0 to pass. Below threshold = strategy needs optimization

## Expert Panel (10 experts)

| Category | Expert | Domain |
|---|---|---|
| Neural Net Fundamentals | Andrej Karpathy | Scaling laws, tokenization, model capabilities, task-model matching |
| Practical LLM Tool Use | Simon Willison | MCP ecosystem, minimal prompts, tool-augmented workflows, pragmatics |
| Agent Architecture | Lilian Weng | Agent patterns (ReAct, Plan-Execute), RAG design, retrieval quality |
| AI Engineering | Swyx (Shawn Wang) | AI engineer discipline, build-vs-prompt, production AI strategy |
| Reasoning & CoT | Jason Wei | Chain-of-thought, instruction design, reasoning trace architecture |
| MLOps & Cost | Chip Huyen | Token economics, model routing, caching, cost-quality Pareto analysis |
| Claude Character | Amanda Askell | System prompt architecture, CLAUDE.md design, Claude-specific patterns |
| Fine-Tuning | Jeremy Howard | Transfer learning, when to fine-tune vs prompt, practical deep learning |
| Evaluation | Hamel Husain | Evals-driven development, skill testing, consistency measurement |
| AI Adoption | Ethan Mollick | Workflow design, jagged frontier, human-AI task allocation |

## Analysis Modes

### Discussion Mode (`--mode discussion`)
Collaborative AI strategy exploration. Experts debate model selection, prompt design, and workflow optimization. Cross-expert validation of AI architectural decisions. Default mode.

### Critique Mode (`--mode critique`)
Systematic review with severity-classified findings (CRITICAL / MAJOR / MINOR). Each finding includes: expert attribution, ROI estimate, specific recommendation, priority ranking, and quality impact. Best paired with `--evidence active` for config-verified findings.

### Socratic Mode (`--mode socratic`)
Strategic questioning to develop AI thinking. Experts challenge model choices, prompt assumptions, and workflow design. No direct answers — forces the user to think about AI strategy fundamentals.

## Evidence Modes

- `--evidence passive` (default): Expert opinions based on provided content only. No tool calls.
- `--evidence active`: Experts inspect CLAUDE.md, settings.json, skill files, MCP configs, and hook definitions. Produces measurement-backed findings with specific file references.

## Focus Areas

- **model-selection**: Task-model matching, tier routing (Haiku/Sonnet/Opus), capability boundaries. Lead: Karpathy. Experts: Karpathy, Huyen, Wei
- **prompt-engineering**: CLAUDE.md design, skill prompts, instruction hierarchy, Claude-specific patterns. Lead: Askell. Experts: Askell, Wei, Willison
- **rag-architecture**: Retrieval strategy, vexp pipeline vs custom RAG, reranking, context injection. Lead: Weng. Experts: Weng, Karpathy, Huyen
- **agent-design**: Subagent patterns, tool orchestration, multi-agent coordination, skill as specialization. Lead: Weng. Experts: Weng, Shawn Wang, Willison
- **evaluation**: Skill testing, output consistency, scoring gate calibration, regression testing. Lead: Husain. Experts: Husain, Huyen, Wei
- **cost-optimization**: Token economics, model routing, caching, session management, build-vs-prompt. Lead: Huyen. Experts: Huyen, Karpathy, Shawn Wang
- **claude-code-workflow**: CLAUDE.md optimization, skill portfolio, hooks, MCP curation, session design, VS Code + macOS integration. Lead: Willison. Experts: Willison, Askell, Mollick, Shawn Wang
- **mcp-tooling**: Server selection, tool orchestration, custom server design, latency optimization. Lead: Willison. Experts: Willison, Weng, Shawn Wang

## Scoring Gate

5 dimensions, each scored 0-10:

| Dimension | Description |
|---|---|
| Model Fit | Right model for each task, appropriate tier routing, capability alignment |
| Prompt Quality | Instruction clarity, CLAUDE.md structure, skill prompt architecture |
| Architecture Soundness | Agent/pipeline design, tool orchestration, workflow coherence |
| Cost-Efficiency | Token economics, model routing, caching, session management |
| Evaluation Coverage | Skill testing, output consistency, quality metrics, regression testing |

**Pass threshold: overall score >= 7.0**

Output includes per-dimension scores, model usage profile, cost analysis, critical issues, expert consensus, and improvement roadmap (immediate / short-term / long-term).

## Model Usage Profile (included in every review)

| Tier | Current | Target (optimal) | Best For |
|---|---|---|---|
| Opus | ?% | 20-30% | Architecture, debugging, complex reasoning |
| Sonnet | ?% | 50-60% | Implementation, code generation, standard tasks |
| Haiku | ?% | 15-25% | Formatting, linting, simple queries, validation |

## Output

AI strategy review document containing:
- Multi-expert analysis with distinct AI perspectives
- Evidence-backed findings (when `--evidence active`)
- Model usage profile with cost-quality optimization path
- Per-dimension scores and overall quality score
- Pass/fail gate result
- ROI-ranked improvement recommendations
- Consensus points and disagreements

**SYNTHESIS ONLY** — this panel produces analysis, strategy recommendations, and cost projections. It does not modify settings, skills, or configs without explicit instruction.

**Next Step**: After review, implement highest-ROI recommendations first. Use `skill-creator` for skill improvements. Update CLAUDE.md based on prompt engineering findings. Use `/sc:spec-panel` to validate specification changes.


## Auto-Fix Policy
Fix ALL findings automatically — high, medium, and low severity. Do not ask which findings to fix. Do not present a menu. Fix everything, then report what was changed.
