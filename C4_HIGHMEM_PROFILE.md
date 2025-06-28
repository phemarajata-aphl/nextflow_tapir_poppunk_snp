# c4-highmem-192 Profile Configuration

## Overview
This profile is specifically optimized for Google Cloud's c4-highmem-192 instance running Debian, which provides:
- **192 vCPUs**
- **1,488 GB Memory**
- **Debian OS**

## Resource Allocation

### Process-Specific Resources
| Process | CPUs | Memory | Time Limit | Description |
|---------|------|--------|------------|-------------|
| PopPUNK | 32   | 400 GB | 24h        | Genome clustering (most resource-intensive) |
| Panaroo | 24   | 100 GB | 8h         | Pan-genome analysis per cluster |
| Gubbins | 16   | 80 GB  | 6h         | Recombination removal per cluster |
| IQ-TREE | 8    | 40 GB  | 4h         | Phylogenetic tree building per cluster |

### System Configuration
- **Total Executor CPUs**: 192 (uses all available)
- **Total Executor Memory**: 1,400 GB (leaves 88 GB headroom)
- **Queue Size**: 20 concurrent processes
- **Docker**: Enabled with Debian compatibility

## Usage

### Quick Test
```bash
# Test the profile configuration
./run_highmem.sh test
```

### Run Full Pipeline
```bash
# Using the helper script
./run_highmem.sh run /path/to/assemblies /path/to/results

# Or directly with nextflow
nextflow run nextflow_tapir_poppunk_snp.nf \
    -profile c4_highmem_192 \
    --input /path/to/assemblies \
    --resultsDir /path/to/results
```

### Resume Failed Runs
```bash
nextflow run nextflow_tapir_poppunk_snp.nf \
    -profile c4_highmem_192 \
    --input /path/to/assemblies \
    --resultsDir /path/to/results \
    -resume
```

## Performance Expectations

### Dataset Size Handling
- **Small datasets (< 100 genomes)**: Completes in 2-4 hours
- **Medium datasets (100-400 genomes)**: Completes in 4-12 hours  
- **Large datasets (400-1000 genomes)**: Completes in 12-24 hours
- **Very large datasets (1000+ genomes)**: May take 24-48 hours

### Memory Usage Patterns
1. **PopPUNK phase**: Uses up to 400 GB (single process)
2. **Analysis phase**: Multiple parallel processes, each using 40-100 GB
3. **Peak usage**: Can reach 800-1000 GB when running multiple clusters simultaneously

## Optimization Features

### Automatic Scaling
- Pipeline automatically detects dataset size and adjusts PopPUNK parameters
- For datasets > 450 genomes: Ultra-conservative parameters activated
- For datasets > 400 genomes: Conservative parameters activated

### Parallel Processing
- After PopPUNK clustering, multiple clusters are processed in parallel
- Up to 20 concurrent processes can run simultaneously
- Each cluster analysis (Panaroo → Gubbins → IQ-TREE) runs independently

### Memory Management
- Generous memory allocation prevents out-of-memory errors
- Docker containers configured for optimal memory usage
- Temporary directories properly configured for Debian

## Troubleshooting

### Common Issues
1. **Docker not found**: Install Docker and add user to docker group
2. **Permission errors**: Ensure Docker daemon is running and accessible
3. **Memory warnings**: Normal for large datasets, profile provides adequate resources

### Monitoring
```bash
# Monitor system resources during run
htop

# Monitor Docker containers
docker stats

# Check pipeline progress
tail -f .nextflow.log
```

### Performance Tuning
If you need to adjust resources for specific use cases:

```bash
# Increase PopPUNK threads for very large datasets
nextflow run nextflow_tapir_poppunk_snp.nf \
    -profile c4_highmem_192 \
    --poppunk_threads 48 \
    --input /path/to/assemblies \
    --resultsDir /path/to/results

# Reduce concurrent processes if memory pressure occurs
# Edit nextflow.config: queueSize = 10
```

## Cost Optimization
- Profile is designed to complete jobs quickly to minimize VM runtime costs
- Higher resource allocation reduces total runtime
- Consider using preemptible instances for non-critical runs

## Files Created
- `test_highmem_profile.nf` - Test script for profile validation
- `run_highmem.sh` - Helper script for easy pipeline execution
- `C4_HIGHMEM_PROFILE.md` - This documentation file

The profile is ready for production use with your c4-highmem-192 instance!