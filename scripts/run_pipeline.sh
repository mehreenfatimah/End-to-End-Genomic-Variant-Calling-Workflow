#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CONFIG="${1:-config/local.env}"
[[ -f "$CONFIG" ]] || {
  echo "Configuration file not found: $CONFIG" >&2
  echo "Create it with: cp config/example.env config/local.env" >&2
  exit 2
}

set -a
# shellcheck disable=SC1090
source "$CONFIG"
set +a

: "${RUN_ID:=ERR14666789}"
: "${THREADS:=4}"
: "${RAW_DIR:=data/raw}"
: "${TRIM_DIR:=results/trimmed}"
: "${REFERENCE_FASTA:=data/reference/reference_genome.fa}"
: "${ADAPTERS_FA:=}"

[[ -s "$REFERENCE_FASTA" ]] || {
  echo "REFERENCE_FASTA does not exist: $REFERENCE_FASTA" >&2
  echo "Choose and document the exact reference build before running." >&2
  exit 2
}
[[ -n "$ADAPTERS_FA" && -f "$ADAPTERS_FA" ]] || {
  echo "ADAPTERS_FA does not exist: $ADAPTERS_FA" >&2
  exit 2
}

./scripts/00_check_dependencies.sh
./scripts/01_download_sra.sh "$RUN_ID" "$RAW_DIR" "$THREADS"
./scripts/02_qc_trim.sh "$RUN_ID" "$RAW_DIR" "$TRIM_DIR" "$ADAPTERS_FA" "$THREADS"
./scripts/03_align.sh "$RUN_ID" "$REFERENCE_FASTA" "$TRIM_DIR" "$THREADS"
./scripts/04_call_variants_bcftools.sh "$RUN_ID" "$REFERENCE_FASTA" "results/alignment/${RUN_ID}.sorted.bam"
./scripts/05_normalize_variants.sh "$RUN_ID" "$REFERENCE_FASTA"
./scripts/06_summarize_results.sh "$RUN_ID"

echo "Pipeline finished. Review results/run_summary.md and the QC/statistics files before interpreting anything."
