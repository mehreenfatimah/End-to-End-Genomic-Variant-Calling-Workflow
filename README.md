# End-to-End Genomic Variant Calling Workflow

A reproducible bioinformatics workflow for processing public sequencing data, aligning reads to a human reference genome, calling genomic variants, filtering candidate variants, and generating reproducible analysis outputs.

The completed analysis uses public sequencing accession **ERR14666789** with the **human_g1k_v37 / GRCh37** reference genome.

## Real-data results

| Metric | Result |
|---|---:|
| Total reads | 12,464,796 |
| Mapped reads | 12,354,224 |
| Mapping rate | 99.11% |
| Raw variant candidates | 735,133 |
| Filtered variant candidates | 69,052 |
| Read type | Single-end |
| Observed read length | 31 bp |
| Reference | human_g1k_v37 / GRCh37 |
| Alignment | BWA aln + samse |
| Variant calling | bcftools mpileup + call |
| Filtering | QUAL >= 20 and INFO/DP >= 3 |

## Workflow

```text
Public SRA accession
        ↓
      FASTQ
        ↓
     FastQC
        ↓
GRCh37 reference preparation
        ↓
    BWA alignment
        ↓
Sorted + indexed BAM
        ↓
Alignment statistics
        ↓
bcftools variant calling
        ↓
Variant filtering
        ↓
Final variant statistics
```

## Quality control

FastQC was used to evaluate sequencing-read quality before alignment.

The reads showed good base quality and no meaningful adapter contamination. Because the reads were already approximately **31 bp long**, trimming was not performed for the completed real-data run.

Trimming is not included in the current workflow because it was not required for the completed dataset.

## Alignment

Reads were aligned against the **GRCh37** human reference genome using **BWA aln + samse**.

The resulting alignment was sorted and indexed using samtools.

The completed run achieved a **99.11% mapping rate**, with **12,354,224 of 12,464,796 reads mapped**.

## Variant calling

Candidate variants were generated using **bcftools mpileup + call**.

The initial analysis produced:

**735,133 raw variant candidates**

Variants were then filtered using:

- `QUAL >= 20`
- `INFO/DP >= 3`

After filtering:

**69,052 candidate variants remained**

These thresholds are analysis choices for this workflow and should not be interpreted as universal clinical filtering criteria.

## Tools

- SRA Toolkit
- FastQC
- BWA
- samtools
- bcftools
- Bash
- Conda
- Git / GitHub

## Repository structure

```text
End-to-End-Genomic-Variant-Calling-Workflow/
├── .github/
├── config/
├── data/
├── docs/
├── results/
│   ├── qc_raw/
│   └── real_run/
├── scripts/
├── environment.yml
└── README.md
```

Large sequencing files, reference genomes, BAM files, and complete VCF files are intentionally excluded from Git because they can be regenerated from the documented workflow.

## Reproducibility

Create the Conda environment with:

`conda env create -f environment.yml`

Then activate it:

`conda activate variant-calling-workflow`

Create a local configuration file:

`cp config/example.env config/local.env`

Place the GRCh37 reference FASTA at the path specified by `REFERENCE_FASTA` in the local configuration.

Run the complete workflow with:

`./scripts/run_pipeline.sh config/local.env`

The public workflow follows the same single-end processing strategy used for the completed ERR14666789 analysis.

Selected quality-control outputs, alignment statistics, variant statistics, logs, and metadata from the completed real-data run are preserved under `results/`.

## What this project demonstrates

- analysis of public sequencing data
- Linux and Bash workflow development
- FASTQ quality control
- human reference-genome preparation
- short-read alignment
- SAM/BAM processing
- genomic variant calling
- VCF processing
- variant filtering
- alignment and variant statistics
- handling large biological datasets
- reproducible bioinformatics workflows
- scientific interpretation of computational outputs

## Limitations

This project demonstrates a reproducible genomic variant-calling workflow and is **not intended as a clinical diagnostic pipeline**.

The detected variants have not been interpreted as pathogenic or clinically meaningful.

A future extension may add functional variant annotation and downstream machine-learning analysis using real biological annotations.

### Analysis Considerations

The dataset contains 31-bp single-end reads, which can make unique alignment challenging in repetitive genomic regions.

The reported 99.11% mapping rate represents the proportion of mapped reads, not independently verified variant-calling accuracy.

Variant candidates were filtered using QUAL >= 20 and INFO/DP >= 3. These thresholds were selected for this analysis and do not constitute clinical validation.

