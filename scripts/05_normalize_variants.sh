#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RUN_ID="${1:-ERR14666789}"
REF="${2:-data/reference/reference_genome.fa}"
IN_VCF="${3:-results/variants/${RUN_ID}.raw.vcf.gz}"
OUT_VCF="${4:-results/variants/${RUN_ID}.normalized.vcf.gz}"

command -v bcftools >/dev/null 2>&1 || { echo "Missing dependency: bcftools" >&2; exit 1; }
[[ -s "$REF" ]] || { echo "Reference FASTA not found: $REF" >&2; exit 2; }
[[ -s "$IN_VCF" ]] || { echo "Input VCF not found: $IN_VCF" >&2; exit 2; }
mkdir -p "$(dirname "$OUT_VCF")"

echo "Normalizing variants against the selected reference..."
bcftools norm -f "$REF" -m -any "$IN_VCF" -Oz -o "$OUT_VCF"
bcftools index -f "$OUT_VCF"
bcftools stats "$OUT_VCF" > "${OUT_VCF%.vcf.gz}.stats.txt"

echo "Normalized VCF written to $OUT_VCF"
