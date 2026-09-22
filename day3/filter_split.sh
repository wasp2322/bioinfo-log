#!/usr/bin/env bash
# usage: filter_split.sh <raw.vcf.gz> <out_prefix>
set -euo pipefail
REF=$HOME/bioinfo/day2/ref/chr21.fa
IN=$1; OUT=$2

gatk SelectVariants --verbosity WARNING -R "$REF" -V "$IN" --select-type-to-include SNP -O "$OUT.snps.raw.vcf.gz"
gatk VariantFiltration --verbosity WARNING -R "$REF" -V "$OUT.snps.raw.vcf.gz" -O "$OUT.snps.vcf.gz" \
  --filter-name QD2           --filter-expression "QD < 2.0" \
  --filter-name QUAL30        --filter-expression "QUAL < 30.0" \
  --filter-name SOR3          --filter-expression "SOR > 3.0" \
  --filter-name FS60          --filter-expression "FS > 60.0" \
  --filter-name MQ40          --filter-expression "MQ < 40.0" \
  --filter-name MQRankSum     --filter-expression "MQRankSum < -12.5" \
  --filter-name ReadPosRank8  --filter-expression "ReadPosRankSum < -8.0"

gatk SelectVariants --verbosity WARNING -R "$REF" -V "$IN" --select-type-to-include INDEL -O "$OUT.indels.raw.vcf.gz"
gatk VariantFiltration --verbosity WARNING -R "$REF" -V "$OUT.indels.raw.vcf.gz" -O "$OUT.indels.vcf.gz" \
  --filter-name QD2           --filter-expression "QD < 2.0" \
  --filter-name QUAL30        --filter-expression "QUAL < 30.0" \
  --filter-name FS200         --filter-expression "FS > 200.0" \
  --filter-name ReadPosRank20 --filter-expression "ReadPosRankSum < -20.0"
