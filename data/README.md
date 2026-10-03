# Data provenance and local data layout

The recovered coursework selected **SRA run `ERR14666789`** (experiment `ERX14068296`) for an educational genomic variant-calling workflow. The archived report described it as human Illumina sequencing associated with a study of Punic genetic diversity.

That description is preserved as part of the recovered coursework context. Before using the accession for new scientific claims, verify the current archive metadata directly in NCBI SRA/ENA.

## Why sequencing data are not committed

FASTQ, BAM, and VCF files can become large and should not be duplicated in an ordinary Git repository. The workflow downloads the public accession locally and `.gitignore` excludes generated sequencing/alignment files.

## Expected local layout

```text
data/
├── raw/
│   ├── ERR14666789_1.fastq.gz
│   └── ERR14666789_2.fastq.gz
└── reference/
    └── reference_genome.fa
```

## Reference genome

A reference FASTA is deliberately not bundled. Put the reference you choose at the path specified by `REFERENCE_FASTA` in `config/local.env` and document the exact build/version before interpreting coordinates or variants.
