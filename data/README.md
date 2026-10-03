# Data layout

This project uses public sequencing accession **ERR14666789**.

The completed analysis used a **single-end FASTQ** file.

## Expected local layout

data/
├── raw/
│   └── ERR14666789.fastq
└── reference/
    └── human_g1k_v37.fasta

Large sequencing and reference files are intentionally excluded from GitHub.

The sequencing data can be retrieved from the public accession using SRA Toolkit.

The human GRCh37 reference FASTA is also kept outside Git and must be available locally before running the alignment stage.
