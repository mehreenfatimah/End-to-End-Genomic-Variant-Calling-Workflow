#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-config/local.env}"

[[ -f "$CONFIG" ]] || {
    echo "Configuration file not found: $CONFIG" >&2
    echo "Create it with: cp config/example.env config/local.env" >&2
    exit 2
}

set -a
source "$CONFIG"
set +a

RUN_ID="${RUN_ID:-ERR14666789}"
THREADS="${THREADS:-6}"
RAW_DIR="${RAW_DIR:-data/raw}"
REFERENCE_FASTA="${REFERENCE_FASTA:-data/reference/human_g1k_v37.fasta}"

[[ -s "$REFERENCE_FASTA" ]] || {
    echo "Reference FASTA not found: $REFERENCE_FASTA" >&2
    exit 2
}

./scripts/00_check_dependencies.sh

./scripts/01_download_sra.sh \
    "$RUN_ID" \
    "$RAW_DIR" \
    "$THREADS"

./scripts/02_qc.sh \
    "$RUN_ID" \
    "$RAW_DIR" \
    "$THREADS"

./scripts/03_align.sh \
    "$RUN_ID" \
    "$REFERENCE_FASTA" \
    "$RAW_DIR/${RUN_ID}.fastq" \
    "$THREADS"

./scripts/04_call_variants_bcftools.sh \
    "$RUN_ID" \
    "$REFERENCE_FASTA" \
    "results/real_run/alignment/${RUN_ID}.sorted.bam" \
    "$THREADS"

./scripts/05_filter_variants.sh \
    "$RUN_ID" \
    "$THREADS"

./scripts/06_summarize_results.sh \
    "$RUN_ID"

echo
echo "Pipeline complete."
