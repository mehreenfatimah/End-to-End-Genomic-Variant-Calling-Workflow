#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RUN_ID="${1:-ERR14666789}"
VCF="${2:-results/variants/${RUN_ID}.normalized.vcf.gz}"
FLAGSTAT="${3:-results/alignment/${RUN_ID}.flagstat.txt}"
OUT="${4:-results/run_summary.md}"

command -v bcftools >/dev/null 2>&1 || { echo "Missing dependency: bcftools" >&2; exit 1; }
[[ -s "$VCF" ]] || { echo "Normalized VCF not found: $VCF" >&2; exit 2; }

total=$(bcftools view -H "$VCF" | wc -l | tr -d ' ')
snps=$(bcftools view -v snps -H "$VCF" | wc -l | tr -d ' ')
indels=$(bcftools view -v indels -H "$VCF" | wc -l | tr -d ' ')

{
  echo "# Workflow run summary"
  echo
  echo "- **Run accession:** \`$RUN_ID\`"
  echo "- **Normalized variant records:** $total"
  echo "- **SNP records:** $snps"
  echo "- **Indel records:** $indels"
  echo
  echo "These are observed counts from the locally generated VCF. They are not clinical interpretations."
  if [[ -s "$FLAGSTAT" ]]; then
    echo
    echo "## Alignment flagstat"
    echo
    echo '```text'
    cat "$FLAGSTAT"
    echo '```'
  fi
} > "$OUT"

echo "Summary written to $OUT"
