#!/bin/bash
set -euo pipefail

THREADS=$1
SAMPLE_ID=$2
R1=$3
R2=$4
REF=$5

mkdir -p results/aligned results/sorted results/marked_duplicates results/germline

# 1. Align reads to reference
bwa mem -t "$THREADS" -M \
    -R "@RG\tID:${SAMPLE_ID}\tSM:${SAMPLE_ID}\tPL:ILLUMINA" \
    "$REF" "$R1" "$R2" \
    | samtools view -Sb - > results/aligned/${SAMPLE_ID}.bam

# 2. Sort and index
samtools sort -@ "$THREADS" -o results/sorted/${SAMPLE_ID}.sorted.bam results/aligned/${SAMPLE_ID}.bam
samtools index results/sorted/${SAMPLE_ID}.sorted.bam
samtools flagstat results/sorted/${SAMPLE_ID}.sorted.bam > results/sorted/${SAMPLE_ID}_flagstat.txt

# 3. Mark duplicates
gatk MarkDuplicates \
    -I results/sorted/${SAMPLE_ID}.sorted.bam \
    -O results/marked_duplicates/${SAMPLE_ID}.markdup.bam \
    -M results/marked_duplicates/${SAMPLE_ID}_metrics.txt \
    --CREATE_INDEX true

# 4. Call variants (per-sample GVCF)
gatk HaplotypeCaller \
    -R "$REF" \
    -I results/marked_duplicates/${SAMPLE_ID}.markdup.bam \
    -O results/germline/${SAMPLE_ID}.g.vcf.gz \
    -ERC GVCF

# 5. Genotype the GVCF into final variant calls
gatk GenotypeGVCFs \
    -R "$REF" \
    -V results/germline/${SAMPLE_ID}.g.vcf.gz \
    -O results/germline/${SAMPLE_ID}.final.vcf.gz

echo "Done: results/germline/${SAMPLE_ID}.final.vcf.gz"
