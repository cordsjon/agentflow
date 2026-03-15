#!/bin/bash
# rebuild-registry.sh — Regenerate experts/registry.yaml from individual files
#
# Scans experts/individuals/, experts/packs/, and experts/panels/ to produce
# a consolidated registry.yaml. This is the source of truth for panel assembly.
#
# Usage: ./scripts/rebuild-registry.sh
#
# Requires: yq (https://github.com/mikefarah/yq) for YAML frontmatter parsing
#           If yq is not installed, falls back to grep-based extraction.

set -euo pipefail

EXPERTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/experts"
REGISTRY="$EXPERTS_DIR/registry.yaml"
INDIVIDUALS="$EXPERTS_DIR/individuals"
PACKS="$EXPERTS_DIR/packs"
PANELS="$EXPERTS_DIR/panels"

echo "# Expert Registry — Auto-generated" > "$REGISTRY"
echo "# Run: ./scripts/rebuild-registry.sh to regenerate" >> "$REGISTRY"
echo "# Last rebuilt: $(date -u +%Y-%m-%d)" >> "$REGISTRY"
echo "" >> "$REGISTRY"

# --- Panels ---
echo "panels:" >> "$REGISTRY"
for panel_file in "$PANELS"/*.yaml; do
    [[ "$(basename "$panel_file")" == "_TEMPLATE.yaml" ]] && continue
    [ ! -f "$panel_file" ] && continue

    panel_name=$(grep '^name:' "$panel_file" | head -1 | sed 's/name: *//')
    panel_desc=$(grep '^description:' "$panel_file" | head -1 | sed 's/description: *"//' | sed 's/"$//')
    default_experts=$(grep -A 50 '^default-experts:' "$panel_file" | head -1 | sed 's/default-experts: *//')

    echo "  $panel_name:" >> "$REGISTRY"
    echo "    description: \"$panel_desc\"" >> "$REGISTRY"
    echo "    default-experts: $default_experts" >> "$REGISTRY"
    echo "" >> "$REGISTRY"
done

# --- Packs ---
echo "packs:" >> "$REGISTRY"
for pack_file in "$PACKS"/*.md; do
    [[ "$(basename "$pack_file")" == "_TEMPLATE.md" ]] && continue
    [ ! -f "$pack_file" ] && continue

    # Extract frontmatter fields
    slug=$(grep '^slug:' "$pack_file" | head -1 | sed 's/slug: *//')
    experts=$(grep '^experts:' "$pack_file" | head -1 | sed 's/experts: *//')
    panels=$(grep '^panels:' "$pack_file" | head -1 | sed 's/panels: *//')

    echo "  $slug:" >> "$REGISTRY"
    echo "    experts: $experts" >> "$REGISTRY"
    echo "    panels: $panels" >> "$REGISTRY"
    echo "" >> "$REGISTRY"
done

# --- Experts ---
echo "experts:" >> "$REGISTRY"
total=0
total_tokens=0
for expert_file in "$INDIVIDUALS"/*.md; do
    [[ "$(basename "$expert_file")" == "_TEMPLATE.md" ]] && continue
    [ ! -f "$expert_file" ] && continue

    slug=$(grep '^slug:' "$expert_file" | head -1 | sed 's/slug: *//')
    domain=$(grep '^domain:' "$expert_file" | head -1 | sed 's/domain: *"//' | sed 's/"$//')
    panels=$(grep '^panels:' "$expert_file" | head -1 | sed 's/panels: *//')
    token_cost=$(grep '^token-cost:' "$expert_file" | head -1 | sed 's/token-cost: *//')

    echo "  $slug: { domain: \"$domain\", panels: $panels, token-cost: $token_cost }" >> "$REGISTRY"
    total=$((total + 1))
    total_tokens=$((total_tokens + token_cost))
done

echo "" >> "$REGISTRY"
echo "total-experts: $total" >> "$REGISTRY"
echo "total-token-budget: $total_tokens" >> "$REGISTRY"

echo "Registry rebuilt: $total experts, ${total_tokens} tokens total budget"
echo "Written to: $REGISTRY"
