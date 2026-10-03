#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
mkdir -p results

required=(prefetch fasterq-dump fastqc trimmomatic bwa samtools bcftools gzip)
missing=0

for cmd in "${required[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'OK      %s\n' "$cmd"
  else
    printf 'MISSING %s\n' "$cmd" >&2
    missing=1
  fi
done

{
  echo "Tool versions detected on $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "======================================================"
  prefetch --version 2>&1 | head -n 1 || true
  fasterq-dump --version 2>&1 | head -n 1 || true
  fastqc --version 2>&1 | head -n 1 || true
  trimmomatic -version 2>&1 | head -n 1 || true
  bwa 2>&1 | grep -m1 '^Version:' || true
  samtools --version 2>&1 | head -n 1 || true
  bcftools --version 2>&1 | head -n 1 || true
} > results/tool_versions.txt

if [[ "$missing" -ne 0 ]]; then
  echo "Install the missing tools (for example with environment.yml) before running the pipeline." >&2
  exit 1
fi

echo "Dependency check passed. Versions saved to results/tool_versions.txt"
