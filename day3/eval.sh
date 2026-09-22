#!/usr/bin/env bash
# usage: eval.sh <label> <prefix>  (<prefix>.snps.vcf.gz / <prefix>.indels.vcf.gz を採点)
set -euo pipefail
E=$HOME/bioinfo/day2/eval
SDF=$HOME/bioinfo/day2/ref/chr21.sdf
LABEL=$1; P=$2

for T in snps indels; do
  rm -rf "vcfeval_${LABEL}_$T"
  rtg vcfeval -b "$E/truth.$T.vcf.gz" -c "$P.$T.vcf.gz" -e "$E/conf.region.bed" \
    -t "$SDF" -o "vcfeval_${LABEL}_$T" --ref-overlap > /dev/null
  awk -v L="$LABEL" -v T="$T" '$1=="None"{printf "%s\t%s\tP=%s\tS=%s\tF=%s\tFP=%s\tFN=%s\n", L, T, $6, $7, $8, $4, $5}' \
    "vcfeval_${LABEL}_$T/summary.txt"
done
