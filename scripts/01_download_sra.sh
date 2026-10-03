#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RUN_ID="${1:-ERR14666789}"
OUT="${2:-data/raw}"
THREADS="${3:-4}"
mkdir -p "$OUT"

for cmd in prefetch fasterq-dump gzip; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing dependency: $cmd" >&2; exit 1; }
done

R1="$OUT/${RUN_ID}_1.fastq.gz"
R2="$OUT/${RUN_ID}_2.fastq.gz"
if [[ -s "$R1" && -s "$R2" ]]; then
  echo "FASTQ files already exist; skipping download:"
  echo "  $R1"
  echo "  $R2"
  exit 0
fi

echo "Public accession: $RUN_ID"
echo "Before continuing, make sure you have enough free disk space for the full accession and fasterq-dump temporary files."
echo "Prefetching accession..."
prefetch "$RUN_ID"

echo "Converting the prefetched accession to paired FASTQ..."
fasterq-dump --split-files --threads "$THREADS" --outdir "$OUT" "$RUN_ID"

for fq in "$OUT/${RUN_ID}_1.fastq" "$OUT/${RUN_ID}_2.fastq"; do
  [[ -s "$fq" ]] || { echo "Expected FASTQ not found: $fq" >&2; exit 2; }
  gzip -f "$fq"
done

echo "FASTQ files written under $OUT"
