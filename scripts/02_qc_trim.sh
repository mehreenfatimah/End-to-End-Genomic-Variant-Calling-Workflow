#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RUN_ID="${1:-ERR14666789}"
RAW="${2:-data/raw}"
OUT="${3:-results/trimmed}"
ADAPTERS="${4:-}"
THREADS="${5:-4}"

mkdir -p "$OUT" results/qc/raw results/qc/trimmed
R1="$RAW/${RUN_ID}_1.fastq.gz"
R2="$RAW/${RUN_ID}_2.fastq.gz"

for cmd in fastqc trimmomatic; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing dependency: $cmd" >&2; exit 1; }
done
[[ -s "$R1" ]] || { echo "Raw read file not found: $R1" >&2; exit 2; }
[[ -s "$R2" ]] || { echo "Raw read file not found: $R2" >&2; exit 2; }
[[ -n "$ADAPTERS" && -f "$ADAPTERS" ]] || {
  echo "Adapter FASTA not found. Pass it as argument 4 or set ADAPTERS_FA in config/local.env." >&2
  exit 2
}

echo "Running FastQC on raw reads..."
fastqc --threads "$THREADS" -o results/qc/raw "$R1" "$R2"

echo "Trimming paired-end reads..."
trimmomatic PE -threads "$THREADS" \
  "$R1" "$R2" \
  "$OUT/${RUN_ID}_1_paired.fastq.gz" "$OUT/${RUN_ID}_1_unpaired.fastq.gz" \
  "$OUT/${RUN_ID}_2_paired.fastq.gz" "$OUT/${RUN_ID}_2_unpaired.fastq.gz" \
  "ILLUMINACLIP:${ADAPTERS}:2:30:10" SLIDINGWINDOW:4:20 MINLEN:36

echo "Running FastQC on paired trimmed reads..."
fastqc --threads "$THREADS" -o results/qc/trimmed \
  "$OUT/${RUN_ID}_1_paired.fastq.gz" "$OUT/${RUN_ID}_2_paired.fastq.gz"
