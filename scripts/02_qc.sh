#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${1:-ERR14666789}"
RAW_DIR="${2:-data/raw}"
THREADS="${3:-6}"

FASTQ="$RAW_DIR/${RUN_ID}.fastq"
OUT="results/qc_raw"

mkdir -p "$OUT"

command -v fastqc >/dev/null 2>&1 || {
    echo "Missing dependency: fastqc" >&2
    exit 1
}

[[ -s "$FASTQ" ]] || {
    echo "FASTQ not found: $FASTQ" >&2
    exit 2
}

echo "Running FastQC on single-end reads..."

fastqc \
    --threads "$THREADS" \
    --outdir "$OUT" \
    "$FASTQ"

echo "FastQC completed."
