#!/usr/bin/env bash
# BQSR → ApplyBQSR → HaplotypeCaller
set -euo pipefail

REF=$HOME/bioinfo/day2/ref/chr21.fa
BAM=$HOME/bioinfo/day2/work/HG002.md.bam
K=$HOME/bioinfo/day3/known
REGION=chr21:14000000-24000000
cd $HOME/bioinfo/day3/work

KS=()
for f in "$K"/*.chr21.vcf.gz; do KS+=(--known-sites "$f"); done

gatk BaseRecalibrator -R "$REF" -I "$BAM" -L "$REGION" "${KS[@]}" -O HG002.recal.table
gatk ApplyBQSR -R "$REF" -I "$BAM" --bqsr-recal-file HG002.recal.table -O HG002.bqsr.bam
gatk --java-options "-Xmx6g" HaplotypeCaller -R "$REF" -I HG002.bqsr.bam -L "$REGION" -O HG002.bqsr.raw.vcf.gz

echo "DONE: $(date)"
