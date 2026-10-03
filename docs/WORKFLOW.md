# Variant Calling Workflow

## Overview

This workflow processes public sequencing data through quality control, reference-genome preparation, read alignment, variant calling, filtering, and result summarization.

## Dataset

- Accession: ERR14666789
- Sequencing type: single-end
- Observed read length: 31 bp
- Reference genome: human_g1k_v37 / GRCh37

## Workflow stages

1. Obtain public sequencing data using SRA Toolkit.
2. Convert sequencing data to FASTQ.
3. Evaluate sequencing-read quality with FastQC.
4. Prepare and index the GRCh37 reference genome.
5. Align reads using BWA aln and samse.
6. Sort and index the resulting BAM file using samtools.
7. Generate alignment statistics.
8. Call candidate variants using bcftools mpileup and call.
9. Apply quality/depth filtering.
10. Generate variant statistics and reproducibility records.

## Quality-control decision

FastQC showed good base quality and no meaningful adapter contamination.

Because the sequencing reads were already approximately 31 bp long, trimming was not performed for the completed real-data run.

## Completed run

- Total reads: 12,464,796
- Mapped reads: 12,354,224
- Mapping rate: 99.11%
- Raw variant candidates: 735,133
- Filtered variant candidates: 69,052

## Variant filtering

The completed portfolio run used:

- QUAL >= 20
- INFO/DP >= 3

These thresholds are specific analysis choices for this workflow and are not universal clinical filtering criteria.

## Data management

Large FASTQ, reference-genome, BAM, and complete VCF files are intentionally excluded from GitHub.

Smaller QC reports, alignment statistics, variant statistics, metadata, and logs are retained as evidence of the completed analysis.
