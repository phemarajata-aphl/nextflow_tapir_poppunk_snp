# TAPIR + PopPUNK + Per-Clade SNP Analysis Pipeline

A Nextflow DSL2 pipeline optimized for phylogenetic analysis of bacterial genomes using PopPUNK clustering followed by per-cluster SNP analysis.

## Overview

This pipeline performs:
1. **PopPUNK clustering** - Groups assembled genomes into clusters based on genetic similarity
2. **Per-cluster analysis**:
   - **Panaroo** - Pan-genome analysis to identify core genes
   - **Gubbins** - Removes recombination and identifies SNPs
   - **IQ-TREE** - Builds phylogenetic trees from filtered SNPs

## System Requirements

- **Hardware**: Intel Core Ultra 9 185H (22 threads) with 64GB RAM (optimized for ~400 FASTA files)
- **Software**: 
  - Nextflow (v23+)
  - Docker (running locally)
  - Docker images (pulled automatically):
    - `mwanji/poppunk:2.6.2`
    - `quay.io/biocontainers/panaroo:1.7.0--pyhdfd78af_0`
    - `quay.io/biocontainers/gubbins:2.4.1--py36hb206151_3`
    - `quay.io/biocontainers/iqtree:2.1.2--hdc80bf6_0`

## Usage

### Basic Usage
```bash
nextflow run nextflow_tapir_poppunk_snp.nf --input ./assemblies --resultsDir ./results
```

### Input Requirements
- Directory containing FASTA assembly files
- Supported extensions: `.fasta`, `.fa`, `.fas`
- Minimum 3 genomes per cluster for meaningful analysis

### Parameters
- `--input`: Path to directory containing FASTA assemblies (required)
- `--resultsDir`: Path to output directory (required)
- `--poppunk_threads`: Threads for PopPUNK (default: 22)
- `--panaroo_threads`: Threads for Panaroo (default: 16) 
- `--gubbins_threads`: Threads for Gubbins (default: 8)
- `--iqtree_threads`: Threads for IQ-TREE (default: 4)

### Example
```bash
# Run with custom thread allocation
nextflow run nextflow_tapir_poppunk_snp.nf \
    --input ./my_assemblies \
    --resultsDir ./my_results \
    --poppunk_threads 20 \
    --panaroo_threads 12
```

## Output Structure
```
results/
├── poppunk/                    # PopPUNK clustering results
│   └── clusters.csv           # Cluster assignments
├── cluster_1/                 # Results for cluster 1
│   ├── panaroo/              # Pan-genome analysis
│   ├── gubbins/              # Recombination removal
│   └── iqtree/               # Phylogenetic tree
├── cluster_2/                 # Results for cluster 2
│   └── ...
├── pipeline_report.html       # Execution report
├── timeline.html             # Timeline report
└── trace.txt                 # Process trace
```

## Resource Optimization

The pipeline is optimized for your system:
- **PopPUNK**: 22 threads, 48GB RAM (most resource-intensive)
- **Panaroo**: 16 threads, 24GB RAM per cluster
- **Gubbins**: 8 threads, 12GB RAM per cluster  
- **IQ-TREE**: 4 threads, 6GB RAM per cluster
- **Queue limit**: 10 concurrent processes to manage memory

## Troubleshooting

### Common Issues
1. **No FASTA files found**: Check file extensions and input path
2. **Docker permission errors**: Ensure Docker is running and user has permissions
3. **Memory issues**: Reduce thread counts or process fewer files at once
4. **Small clusters skipped**: Clusters with <3 genomes are automatically filtered out

### Help
```bash
nextflow run nextflow_tapir_poppunk_snp.nf --help
```

## Performance Notes

- Optimized for ~400 FASTA files on 22-core system with 64GB RAM
- PopPUNK clustering is the most memory-intensive step
- Per-cluster analyses run in parallel after clustering
- Total runtime depends on number of clusters and cluster sizes