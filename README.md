# Germline Variant Calling Pipeline — *E. coli*

A complete germline variant calling pipeline built with `bwa` and `GATK`, applied to real public sequencing data from a 50,000-generation bacterial evolution experiment.

## Background

This pipeline follows the standard variant-calling workflow used across genomics (alignment → sort → mark duplicates → variant calling), adapted here for a bacterial genome. It's demonstrated on real data from the [E. coli long-term evolution experiment](https://en.wikipedia.org/wiki/E._coli_long-term_evolution_experiment) (Lenski lab) — one of the longest-running evolution experiments in science, tracking 12 *E. coli* populations since 1988.

The sample analyzed, **SRR2584866**, is from generation 50,000 of population Ara-3. By this point, this population had evolved two remarkable traits:
- The ability to grow on citrate (**Cit+**) — a trait *E. coli* essentially never naturally evolves
- A **hypermutator phenotype** — a breakdown in DNA repair that caused mutations to accumulate far faster than normal

This is exactly why the pipeline finds hundreds of variants in this sample rather than a handful — it's correctly detecting a real, scientifically documented burst of mutation, not noise.

## Pipeline

| Stage | Tool | Purpose |
|---|---|---|
| Alignment | `bwa mem` | Maps each sequencing read to its position on the reference genome |
| Sort & index | `samtools` | Orders reads by genome position for fast access |
| Mark duplicates | `gatk MarkDuplicates` | Flags reads sequenced more than once by accident |
| Variant calling | `gatk HaplotypeCaller` | Records evidence at every position (GVCF mode) |
| Genotyping | `gatk GenotypeGVCFs` | Filters down to confident, real variant calls |

**Note:** Base Quality Score Recalibration (BQSR) is intentionally skipped. BQSR requires a database of known common variants (like dbSNP for humans) to correct machine confidence scores — no such database exists for this *E. coli* strain.

## Results

| Metric | Value |
|---|---|
| Reads mapped | 99.98% |
| Properly paired | 99.05% |
| Duplication rate | 0.16% |
| Total variants called | 844 |
| Homozygous (fixed in population) | 764 (91%) |
| Heterozygous (still spreading) | 79 (9%) |

The 91%/9% split is itself a small snapshot of evolution in progress: most detected mutations had already fixed throughout the sequenced population, while roughly 1 in 10 was still sweeping through when the sample was taken.

## Project structure

```
germline-variant-pipeline/
├── data/
│   └── reference/              # E. coli REL606 genome + indexes
├── results/
│   ├── sorted/                 # Alignment QC (flagstat)
│   ├── marked_duplicates/      # Duplication metrics
│   └── germline/               # Final variant calls (.vcf.gz)
├── scripts/
│   ├── install_tools.sh        # One-time environment setup
│   └── run_pipeline.sh         # The pipeline itself
└── README.md
```

## Usage

**1. Install dependencies** (bwa, samtools, GATK):
```bash
bash scripts/install_tools.sh
```

**2. Download the data** (reference genome + real sequencing reads, ~230MB total):
```bash
mkdir -p data/reference data/raw_reads
wget -O data/reference/ecoli_rel606.fasta.gz https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/017/985/GCA_000017985.1_ASM1798v1/GCA_000017985.1_ASM1798v1_genomic.fna.gz
gunzip data/reference/ecoli_rel606.fasta.gz

wget -O data/raw_reads/sub.tar.gz https://ndownloader.figshare.com/files/14418248
cd data/raw_reads && tar xvf sub.tar.gz && mv sub/* . && rmdir sub && rm sub.tar.gz && cd ../..
```

**3. Index the reference:**
```bash
bwa index data/reference/ecoli_rel606.fasta
samtools faidx data/reference/ecoli_rel606.fasta
gatk CreateSequenceDictionary -R data/reference/ecoli_rel606.fasta
```

**4. Run the pipeline:**
```bash
bash scripts/run_pipeline.sh 4 SRR2584866 \
    data/raw_reads/SRR2584866_1.trim.sub.fastq \
    data/raw_reads/SRR2584866_2.trim.sub.fastq \
    data/reference/ecoli_rel606.fasta
```

Output: `results/germline/SRR2584866.final.vcf.gz`

## What I'd add next

- Annotate variants with VEP to identify which genes were affected
- Compare against the earlier-generation samples (`SRR2584863`, `SRR2589044`) also available from this dataset, to track when the hypermutator phenotype emerged
- Extend to a full multi-sample joint genotyping workflow

## Author

Sanwaz Kausar Ansari — MSc Bioinformatics, University of Birmingham
