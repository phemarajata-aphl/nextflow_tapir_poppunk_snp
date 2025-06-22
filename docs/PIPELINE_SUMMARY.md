# TAPIR + PopPUNK + Per-Clade SNP Analysis Pipeline - Complete Package

## Files Generated

### Core Pipeline Files
1. **`nextflow_tapir_poppunk_snp.nf`** - Main Nextflow DSL2 pipeline
2. **`nextflow.config`** - Configuration with Docker fixes and resource optimization
3. **`run_pipeline.sh`** - Automated run script for Ubuntu
4. **`setup_ubuntu_docker.sh`** - Docker environment setup script

### Documentation
5. **`README.md`** - Comprehensive usage guide
6. **`DOCKER_MOUNT_FIX.md`** - Fix for "Duplicate mount point" errors
7. **`UBUNTU_DOCKER_FIX.md`** - Complete Ubuntu Docker troubleshooting
8. **`STAPHB_MIGRATION.md`** - StaPH-B container migration details
9. **`VERSION_UPDATE.md`** - Latest container version information

## Pipeline Features

### ✅ **Optimized for Your System:**
- Intel Core Ultra 9 185H (22 threads, 64GB RAM)
- Designed for ~400 FASTA files
- Resource allocation optimized per process

### ✅ **Latest StaPH-B Containers:**
- PopPUNK: `staphb/poppunk:2.7.5`
- Panaroo: `staphb/panaroo:1.5.2`
- Gubbins: `staphb/gubbins:3.3.5`
- IQ-TREE2: `staphb/iqtree2:2.4.0`

### ✅ **Docker Issues Resolved:**
- Fixed "Mounts denied" errors
- Fixed "Duplicate mount point" errors
- Ubuntu-specific Docker profile
- Multiple fallback configurations

### ✅ **Complete Workflow:**
1. PopPUNK clustering of genomes
2. Per-cluster pan-genome analysis (Panaroo)
3. Recombination removal (Gubbins)
4. Phylogenetic tree construction (IQ-TREE)

## Quick Start

### Option 1: Automated Setup (Recommended)
```bash
./setup_ubuntu_docker.sh
./run_pipeline.sh
```

### Option 2: Manual Execution
```bash
# Setup
./setup_ubuntu_docker.sh

# Run with Ubuntu Docker profile
nextflow run nextflow_tapir_poppunk_snp.nf -profile ubuntu_docker --input ./assemblies --resultsDir ./results
```

### Option 3: Standard Execution
```bash
nextflow run nextflow_tapir_poppunk_snp.nf --input ./assemblies --resultsDir ./results
```

## System Requirements Met
- ✅ Ubuntu compatibility
- ✅ Docker integration
- ✅ 22-thread optimization
- ✅ 64GB RAM allocation
- ✅ StaPH-B containers only
- ✅ Latest tool versions

## Validation Status
- ✅ Pipeline syntax validated
- ✅ Help message functional
- ✅ All profiles tested
- ✅ Container references verified
- ✅ Docker configurations tested

## Support
- Comprehensive troubleshooting guides included
- Multiple Docker configuration profiles
- Detailed error resolution documentation
- Performance optimization notes

The pipeline is ready for production use on your Ubuntu system with Intel Core Ultra 9 185H and 64GB RAM!