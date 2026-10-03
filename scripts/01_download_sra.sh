#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${1:-ERR14666789}"
OUT="${2:-data/raw}"
THREADS="${3:-6}"

mkdir -p "$OUT"

FASTQ="$OUT/${RUN_ID}.fastq"

if [[ -s "$FASTQ" ]]; then
    echo "FASTQ already exists: $FASTQ"
    exit 0
fi

for cmd in prefetch fasterq-dump; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing dependency: $cmd" >&2
        exit 1
    }
done

echo "Downloading public accession: $RUN_ID"
prefetch "$RUN_ID"

echo "Converting accession to single-end FASTQ..."
fasterq-dump \
    --threads "$THREADS" \
    --outdir "$OUT" \
    "$RUN_ID"

[[ -s "$FASTQ" ]] || {
    echo "Expected FASTQ not found: $FASTQ" >&2
    exit 2
}

echo "FASTQ created: $FASTQ"
