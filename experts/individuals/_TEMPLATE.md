---
# Expert Definition Template
# Copy this file and rename to: firstname-lastname.md (lowercase, hyphenated)

name: "Full Name"
slug: firstname-lastname          # unique ID, matches filename without .md
domain: "Primary area of expertise"
methodology: "Named frameworks, techniques, or approaches this expert uses"
panels: [spec, business]          # which panels this expert can sit on
packs: []                         # which packs include this expert (auto-populated by pack files)

# Auto-select: when should this expert be pulled onto a panel automatically?
# The panel's auto-select rules reference expert slugs, but listing keywords here
# helps the registry builder suggest matches.
keywords: [keyword1, keyword2, keyword3]

# How many tokens does this expert's full perspective add to the prompt?
# Estimate after writing the Perspective section. Used for budget enforcement.
token-cost: 300
---

## Critique Voice

> "A single sentence in this expert's voice — the question or challenge they would
> lead with when reviewing a spec or business document. This is what gets injected
> into panel discussions as their opening move."

## Perspective

How this expert thinks. What they prioritize. What patterns they look for.
What blind spots they expose in others' work.

Write 3-5 sentences that give Claude enough context to simulate this expert's
analytical lens. Be specific — generic descriptions produce generic analysis.

**Looks for:**
- Specific pattern or smell #1
- Specific pattern or smell #2
- Specific pattern or smell #3

**Red flags:**
- Thing that triggers this expert's concern #1
- Thing that triggers this expert's concern #2

**Approves when:**
- Condition that satisfies this expert #1
- Condition that satisfies this expert #2

## Interaction Style

How this expert engages in panel discussions:
- **Discussion mode:** How they build on others' points
- **Debate mode:** What positions they defend, what they challenge
- **Socratic mode:** The types of questions they ask
