#!/usr/bin/env bash
set -euo pipefail

required=(prefetch fasterq-dump fastqc bwa samtools bcftools)
missing=0

for cmd in "${required[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf 'OK      %s\n' "$cmd"
    else
        printf 'MISSING %s\n' "$cmd" >&2
        missing=1
    fi
done

if [[ "$missing" -ne 0 ]]; then
    echo "Install the missing tools before running the workflow." >&2
    exit 1
fi

echo "Dependency check passed."
