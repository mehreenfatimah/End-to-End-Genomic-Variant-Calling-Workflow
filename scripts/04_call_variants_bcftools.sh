#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RUN_ID="${1:-ERR14666789}"
REF="${2:-data/reference/reference_genome.fa}"
BAM="${3:-results/alignment/${RUN_ID}.sorted.bam}"
OUT="results/variants"
mkdir -p "$OUT"

for cmd in bcftools samtools; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing dependency: $cmd" >&2; exit 1; }
done
[[ -s "$REF" ]] || { echo "Reference FASTA not found: $REF" >&2; exit 2; }
[[ -s "$BAM" ]] || { echo "Alignment BAM not found: $BAM" >&2; exit 2; }
[[ -f "${REF}.fai" ]] || samtools faidx "$REF"

VCF="$OUT/${RUN_ID}.raw.vcf.gz"

echo "Calling candidate variants with bcftools..."
bcftools mpileup -Ou -f "$REF" -a FORMAT/DP,FORMAT/AD "$BAM" \
  | bcftools call -mv -Oz -o "$VCF"

bcftools index -f "$VCF"
bcftools stats "$VCF" > "$OUT/${RUN_ID}.raw.stats.txt"

echo "Raw candidate calls written to $VCF"
