#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${1:-ERR14666789}"

OUT="results/real_run"
ALIGN="$OUT/alignment"
VAR="$OUT/variants"

RAWVCF="$VAR/${RUN_ID}.raw.vcf.gz"
FILTERED="$VAR/${RUN_ID}.filtered.vcf.gz"

[[ -s "$RAWVCF" ]] || {
    echo "Raw VCF not found: $RAWVCF" >&2
    exit 2
}

[[ -s "$FILTERED" ]] || {
    echo "Filtered VCF not found: $FILTERED" >&2
    exit 2
}

bcftools view -H "$RAWVCF" \
    | wc -l \
    > "$VAR/raw_variant_count.txt"

bcftools view -H "$FILTERED" \
    | wc -l \
    > "$VAR/filtered_variant_count.txt"

echo
echo "Mapping results:"
cat "$ALIGN/${RUN_ID}.flagstat.txt"

echo
echo "Raw variant count:"
cat "$VAR/raw_variant_count.txt"

echo
echo "Filtered variant count:"
cat "$VAR/filtered_variant_count.txt"
