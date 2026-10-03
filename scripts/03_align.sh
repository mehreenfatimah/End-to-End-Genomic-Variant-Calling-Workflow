#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RUN_ID="${1:-ERR14666789}"
REF="${2:-data/reference/reference_genome.fa}"
TRIM="${3:-results/trimmed}"
THREADS="${4:-4}"
OUT="results/alignment"
mkdir -p "$OUT"

for cmd in bwa samtools; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing dependency: $cmd" >&2; exit 1; }
done
[[ -s "$REF" ]] || { echo "Reference FASTA not found: $REF" >&2; exit 2; }
R1="$TRIM/${RUN_ID}_1_paired.fastq.gz"
R2="$TRIM/${RUN_ID}_2_paired.fastq.gz"
[[ -s "$R1" ]] || { echo "Trimmed read file not found: $R1" >&2; exit 2; }
[[ -s "$R2" ]] || { echo "Trimmed read file not found: $R2" >&2; exit 2; }

if [[ ! -f "${REF}.bwt" && ! -f "${REF}.0123" ]]; then
  echo "Indexing reference with BWA..."
  bwa index "$REF"
fi
[[ -f "${REF}.fai" ]] || samtools faidx "$REF"

RG="@RG\tID:${RUN_ID}\tSM:${RUN_ID}\tPL:ILLUMINA"
BAM="$OUT/${RUN_ID}.sorted.bam"

echo "Aligning paired reads with BWA-MEM..."
bwa mem -t "$THREADS" -R "$RG" "$REF" "$R1" "$R2" \
  | samtools sort -@ "$THREADS" -o "$BAM" -

samtools index -@ "$THREADS" "$BAM"
samtools quickcheck -v "$BAM"
samtools flagstat -@ "$THREADS" "$BAM" > "$OUT/${RUN_ID}.flagstat.txt"
samtools stats -@ "$THREADS" "$BAM" > "$OUT/${RUN_ID}.samtools_stats.txt"
samtools idxstats "$BAM" > "$OUT/${RUN_ID}.idxstats.txt"

echo "Alignment written to $BAM"
