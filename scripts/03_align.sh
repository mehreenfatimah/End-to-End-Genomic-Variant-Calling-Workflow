#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${1:-ERR14666789}"
REF="${2:-data/reference/human_g1k_v37.fasta}"
FASTQ="${3:-data/raw/ERR14666789.fastq}"
THREADS="${4:-6}"

OUT="results/real_run/alignment"
mkdir -p "$OUT"

for cmd in bwa samtools; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing dependency: $cmd" >&2
        exit 1
    }
done

[[ -s "$REF" ]] || {
    echo "Reference FASTA not found: $REF" >&2
    exit 2
}

[[ -s "$FASTQ" ]] || {
    echo "FASTQ not found: $FASTQ" >&2
    exit 2
}

if [[ ! -f "${REF}.bwt" ]]; then
    echo "Building BWA reference index..."
    bwa index -a bwtsw "$REF"
fi

[[ -f "${REF}.fai" ]] || samtools faidx "$REF"

SAI="$OUT/${RUN_ID}.sai"
TMPBAM="$OUT/${RUN_ID}.sorted.tmp.bam"
BAM="$OUT/${RUN_ID}.sorted.bam"

echo "Aligning single-end reads with BWA aln..."

bwa aln \
    -t "$THREADS" \
    -l 1024 \
    "$REF" \
    "$FASTQ" \
    > "$SAI"

bwa samse \
    "$REF" \
    "$SAI" \
    "$FASTQ" \
| samtools sort \
    -@ "$THREADS" \
    -o "$TMPBAM" -

samtools quickcheck "$TMPBAM"
mv "$TMPBAM" "$BAM"

samtools index -@ "$THREADS" "$BAM"

samtools flagstat \
    -@ "$THREADS" \
    "$BAM" \
    > "$OUT/${RUN_ID}.flagstat.txt"

samtools stats \
    -@ "$THREADS" \
    "$BAM" \
    > "$OUT/${RUN_ID}.samtools_stats.txt"

samtools idxstats \
    "$BAM" \
    > "$OUT/${RUN_ID}.idxstats.txt"

samtools coverage \
    "$BAM" \
    > "$OUT/${RUN_ID}.coverage.txt"

rm -f "$SAI"

echo "Alignment completed: $BAM"
