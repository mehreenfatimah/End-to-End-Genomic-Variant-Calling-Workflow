#!/usr/bin/env bash
set -euo pipefail

THREADS=6
ACC="ERR14666789"

FASTQ="data/raw/${ACC}.fastq"
REF_GZ="data/reference/human_g1k_v37.fasta.gz"
REF="data/reference/human_g1k_v37.fasta"

OUT="results/real_run"
ALIGN="$OUT/alignment"
VAR="$OUT/variants"
LOG="$OUT/logs"

mkdir -p "$ALIGN" "$VAR" "$LOG"

exec > >(tee -a "$LOG/pipeline.log") 2>&1

echo "========================================"
echo " REAL VARIANT CALLING PIPELINE"
echo " Accession: $ACC"
echo " Threads: $THREADS"
echo "========================================"

# -----------------------------
# 1. Check input files
# -----------------------------
echo "[1/9] Checking input files..."

if [[ ! -f "$FASTQ" ]]; then
    echo "ERROR: FASTQ not found: $FASTQ"
    exit 1
fi

if [[ ! -f "$REF_GZ" && ! -f "$REF" ]]; then
    echo "ERROR: GRCh37 reference not found."
    exit 1
fi

# -----------------------------
# 2. Uncompress reference
# -----------------------------
echo "[2/9] Preparing GRCh37 reference..."

if [[ ! -f "$REF" ]]; then
    gzip -dk "$REF_GZ"
else
    echo "Reference already uncompressed."
fi

# -----------------------------
# 3. Build reference indexes
# -----------------------------
echo "[3/9] Building BWA index..."

if [[ ! -f "${REF}.bwt" ]]; then
    bwa index -a bwtsw "$REF"
else
    echo "BWA index already exists."
fi

if [[ ! -f "${REF}.fai" ]]; then
    samtools faidx "$REF"
fi

# -----------------------------
# 4. Align 31 bp single-end reads
# -----------------------------
echo "[4/9] Aligning sequencing reads..."

SAI="$ALIGN/${ACC}.sai"
BAM="$ALIGN/${ACC}.sorted.bam"
TMPBAM="$ALIGN/${ACC}.sorted.tmp.bam"

if [[ ! -f "$BAM" ]]; then

    bwa aln \
        -t "$THREADS" \
        -l 1024 \
        "$REF" \
        "$FASTQ" \
        > "$SAI"

    rm -f "$TMPBAM"

    bwa samse \
        "$REF" \
        "$SAI" \
        "$FASTQ" \
    | samtools sort \
        -@ "$THREADS" \
        -o "$TMPBAM" -

    samtools quickcheck "$TMPBAM"

    mv "$TMPBAM" "$BAM"

else
    echo "BAM already exists."
fi

# -----------------------------
# 5. BAM indexing + mapping stats
# -----------------------------
echo "[5/9] Generating alignment statistics..."

samtools index -@ "$THREADS" "$BAM"

samtools flagstat \
    -@ "$THREADS" \
    "$BAM" \
    > "$ALIGN/${ACC}.flagstat.txt"

samtools stats \
    -@ "$THREADS" \
    "$BAM" \
    > "$ALIGN/${ACC}.samtools_stats.txt"

samtools idxstats \
    "$BAM" \
    > "$ALIGN/${ACC}.idxstats.txt"

samtools coverage \
    "$BAM" \
    > "$ALIGN/${ACC}.coverage.txt"

# -----------------------------
# 6. Variant calling
# -----------------------------
echo "[6/9] Calling variants..."

RAWVCF="$VAR/${ACC}.raw.vcf.gz"

bcftools mpileup \
    --threads "$THREADS" \
    -Ou \
    -f "$REF" \
    -q 20 \
    -Q 20 \
    "$BAM" \
| bcftools call \
    --threads "$THREADS" \
    -mv \
    -Oz \
    -o "$RAWVCF"

bcftools index \
    --threads "$THREADS" \
    -f "$RAWVCF"

# -----------------------------
# 7. Conservative filtering
# -----------------------------
echo "[7/9] Filtering candidate variants..."

FILTERED="$VAR/${ACC}.filtered.vcf.gz"

bcftools filter \
    --threads "$THREADS" \
    -i 'QUAL>=20 && INFO/DP>=3' \
    -Oz \
    -o "$FILTERED" \
    "$RAWVCF"

bcftools index \
    --threads "$THREADS" \
    -f "$FILTERED"

# -----------------------------
# 8. Variant statistics
# -----------------------------
echo "[8/9] Creating variant statistics..."

bcftools stats \
    "$RAWVCF" \
    > "$VAR/${ACC}.raw.stats.txt"

bcftools stats \
    "$FILTERED" \
    > "$VAR/${ACC}.filtered.stats.txt"

bcftools view -H "$RAWVCF" \
    | wc -l \
    > "$VAR/raw_variant_count.txt"

bcftools view -H "$FILTERED" \
    | wc -l \
    > "$VAR/filtered_variant_count.txt"

# Preserve QC decision
unzip -p \
    results/qc_raw/ERR14666789_fastqc.zip \
    ERR14666789_fastqc/summary.txt \
    > "$OUT/fastqc_summary.txt"

cat > "$OUT/run_metadata.txt" <<EOF
Accession: ERR14666789
Sequencing platform: Illumina
Read type: single-end
Observed read length: 31 bp
Reads written to FASTQ: 12,464,796
Reference: human_g1k_v37 / GRCh37
Alignment: BWA aln + samse
Trimming: not performed
Reason for no trimming: FastQC showed good base quality and no adapter contamination; reads were already only 31 bp.
Variant caller: bcftools mpileup + call
Minimum mapping quality for pileup: 20
Minimum base quality for pileup: 20
Portfolio filter: QUAL >= 20 and INFO/DP >= 3
EOF

# -----------------------------
# 9. Build small evidence bundle
# -----------------------------
echo "[9/9] Creating portfolio evidence ZIP..."

python - <<'PY'
from pathlib import Path
import zipfile

files = [
    Path("results/tool_versions.txt"),
    Path("results/qc_raw/ERR14666789_fastqc.html"),
    Path("results/real_run/fastqc_summary.txt"),
    Path("results/real_run/run_metadata.txt"),
    Path("results/real_run/alignment/ERR14666789.flagstat.txt"),
    Path("results/real_run/alignment/ERR14666789.samtools_stats.txt"),
    Path("results/real_run/alignment/ERR14666789.idxstats.txt"),
    Path("results/real_run/alignment/ERR14666789.coverage.txt"),
    Path("results/real_run/variants/ERR14666789.raw.stats.txt"),
    Path("results/real_run/variants/ERR14666789.filtered.stats.txt"),
    Path("results/real_run/variants/raw_variant_count.txt"),
    Path("results/real_run/variants/filtered_variant_count.txt"),
    Path("scripts/run_remaining_real_pipeline.sh"),
    Path("environment.yml"),
]

filtered_vcf = Path(
    "results/real_run/variants/ERR14666789.filtered.vcf.gz"
)

# Include filtered VCF only if reasonably small
if filtered_vcf.exists() and filtered_vcf.stat().st_size < 50 * 1024 * 1024:
    files.append(filtered_vcf)

output = Path("results/portfolio_evidence.zip")

with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as z:
    for f in files:
        if f.exists():
            z.write(f)

print(f"Created: {output}")
PY

rm -f "$SAI"

echo
echo "========================================"
echo " PIPELINE COMPLETE"
echo "========================================"
echo
echo "Mapping results:"
cat "$ALIGN/${ACC}.flagstat.txt"
echo
echo "Raw variant count:"
cat "$VAR/raw_variant_count.txt"
echo
echo "Filtered variant count:"
cat "$VAR/filtered_variant_count.txt"
echo
echo "Evidence bundle:"
ls -lh results/portfolio_evidence.zip
echo
echo "DONE."
