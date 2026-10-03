#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${1:-ERR14666789}"
REF="${2:-data/reference/human_g1k_v37.fasta}"
BAM="${3:-results/real_run/alignment/ERR14666789.sorted.bam}"
THREADS="${4:-6}"

OUT="results/real_run/variants"
mkdir -p "$OUT"

for cmd in bcftools samtools; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing dependency: $cmd" >&2
        exit 1
    }
done

[[ -s "$REF" ]] || {
    echo "Reference FASTA not found: $REF" >&2
    exit 2
}

[[ -s "$BAM" ]] || {
    echo "BAM not found: $BAM" >&2
    exit 2
}

[[ -f "${REF}.fai" ]] || samtools faidx "$REF"

RAWVCF="$OUT/${RUN_ID}.raw.vcf.gz"

echo "Calling candidate variants with bcftools..."

bcftools mpileup \
    --threads "$THREADS" \
    -Ou \
    -f "$REF" \
    -q 20 \
    -Q 20 \
    "$BAM" \
| bcftools call \
    --threads "$THREADS" \
    -mv \
    -Oz \
    -o "$RAWVCF"

bcftools index \
    --threads "$THREADS" \
    -f "$RAWVCF"

bcftools stats \
    "$RAWVCF" \
    > "$OUT/${RUN_ID}.raw.stats.txt"

echo "Raw candidate variants created: $RAWVCF"
