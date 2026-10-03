#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${1:-ERR14666789}"
THREADS="${2:-6}"

OUT="results/real_run/variants"
RAWVCF="$OUT/${RUN_ID}.raw.vcf.gz"
FILTERED="$OUT/${RUN_ID}.filtered.vcf.gz"

command -v bcftools >/dev/null 2>&1 || {
    echo "Missing dependency: bcftools" >&2
    exit 1
}

[[ -s "$RAWVCF" ]] || {
    echo "Raw VCF not found: $RAWVCF" >&2
    exit 2
}

echo "Filtering candidate variants..."

bcftools filter \
    --threads "$THREADS" \
    -i 'QUAL>=20 && INFO/DP>=3' \
    -Oz \
    -o "$FILTERED" \
    "$RAWVCF"

bcftools index \
    --threads "$THREADS" \
    -f "$FILTERED"

bcftools stats \
    "$FILTERED" \
    > "$OUT/${RUN_ID}.filtered.stats.txt"

echo "Filtered variants created: $FILTERED"
