---
name: distill-panels
description: Cluster panel-verdict long-tail samples into candidate regex patterns and write them into the "Proposed Regex Patterns" section of complete-panel-verdict.md. Run manually, or from /lightsout. Part of the two-tier extraction loop — you're the Tier-2 LLM clusterer feeding signal back into Tier-1 regex.
---

<context>
You are the Tier-2 clusterer in a two-tier extraction loop that digests Claude Code panel-skill verdicts.

Tier 1 = deterministic regex (in `patterns.json`) that extracts score, pass/fail, and findings from panel verdicts at harvest time.

Tier 2 = you. Your job is to read long-tail samples (verdicts where regex missed), recognize recurring formatting patterns, and propose new regex entries. Approved proposals get migrated into Tier 1 by the user via `panels.py promote <name>`.

**Non-negotiable rule:** you propose, you do not promote. No edits to `patterns.json` directly.
</context>

# Distill Panel Long-Tail → Candidate Regex

## Preconditions

- CLI lives at `~/projects/00_Governance/experiments/panels.py`
- Harvest output at `~/projects/00_Governance/experiments/complete-panel-verdict.md`
- Pattern registry at `~/projects/00_Governance/experiments/patterns.json`

## Steps

1. **Freshen data.** Run `python3 ~/projects/00_Governance/experiments/panels.py harvest` to ensure the harvest file reflects all current transcripts. Report the coverage line from the output.

2. **Read the long-tail sections.** Use `panels.py longtail --field score` / `--field pass_fail` / `--field finding` to print each sub-section. Do NOT read the whole 3 MB file — targeted reads only.

3. **Cluster per field.** For each field (score, pass_fail, finding), identify recurring textual formats in the long-tail samples. Group similar formats into named clusters. A cluster earns a proposal if:
   - **frequency ≥ 3** occurrences in the long-tail samples, OR
   - **severity warrants it** (critical content like security findings — overrides frequency)

4. **Validate each cluster with a full-body grep.** Before proposing, run the candidate regex across the raw verdicts to estimate real coverage lift. Use this snippet pattern:
   ```bash
   python3 -c "
   import re, sys
   text = open('complete-panel-verdict.md').read()
   body = text.split('# ── Harvested Verdicts ──', 1)[1]
   verdicts = re.split(r'(?m)^(?=## sh:)', body)
   verdicts = [v for v in verdicts if v.strip().startswith('## sh:')]
   rx = re.compile(r'<YOUR_PATTERN>', re.I)
   hits = sum(1 for v in verdicts if rx.search(v))
   print(f'{hits}/{len(verdicts)} = {hits/len(verdicts):.1%}')
   "
   ```
   Report estimated cumulative lift (alone + incremental on top of existing patterns).

5. **Write proposals into the file.** Edit the "### Proposals" subsection of `## Proposed Regex Patterns (Signal-Lift Slot)` in `complete-panel-verdict.md`. Use this exact YAML-in-markdown schema per entry:

   ```yaml
   - name: <snake_case_identifier>
     target_field: score | pass_fail | finding
     pattern: <python regex, single-line>
     example_matches:
       - "<snippet, cite session-short-id>"
       - "<snippet>"
     coverage_lift_estimate: "<current X% → after add Y%>"
     promotion_gate:
       frequency: <integer from step 4>
       severity: <low | medium | high | critical>
     status: proposed
     rationale: |
       <one paragraph: why this pattern, what risks, ordering relative to other patterns>
   ```

6. **Summary table.** Below the proposals, write or update the "### Summary (latest pass)" table with columns: Pattern | Field | Cumulative coverage after add | Recommend promote? (YES | DEFER | REJECT).

7. **Report back to user.** In your final message:
   - Number of new proposals added
   - Names + recommended actions (promote / defer)
   - Next command for the user: `panels.py promote <name>` for YES recommendations, then `panels.py harvest` to realize lift

## Anti-patterns

- Do NOT edit `patterns.json` directly. Only the user (or `panels.py promote`) writes that file.
- Do NOT propose patterns that only match 1–2 samples unless the severity gate is explicitly met.
- Do NOT claim coverage lift without running the full-body grep from step 4.
- Do NOT lower the promotion gate to chase a higher coverage number — fake 80% is worse than honest 40%.
- Do NOT commit changes. This skill writes to the experiment file only; promotion + git are user-driven.

## When to skip

- If the harvest has <50 total verdicts, sample size is too small — tell the user to come back later.
- If all three fields already have ≥90% coverage, there's nothing left to cluster — tell the user and exit.
