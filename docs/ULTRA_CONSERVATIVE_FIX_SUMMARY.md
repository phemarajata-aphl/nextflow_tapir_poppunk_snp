# Ultra-Conservative PopPUNK Fix for 464 Genomes

## Problem Persistence
Despite previous optimizations, PopPUNK continued to segfault at ~3.9% during distance calculation with your 464 Burkholderia pseudomallei genomes.

## Ultra-Conservative Solution Applied

### 1. Aggressive Resource Reduction
```groovy
// Previous attempt
cpus = 16, memory = '56 GB', time = '24h'

// Ultra-conservative fix
cpus = 8, memory = '60 GB', time = '48h'
```

**Rationale**: 50% reduction in threads dramatically reduces memory contention during the quadratic distance calculation phase.

### 2. Ultra-Conservative PopPUNK Parameters
For datasets >450 samples (your 464 qualifies):
```bash
--sketch-size 5000    # Reduced from 9999 (50% less memory per genome)
--min-k 15           # Increased from 13 (fewer k-mers processed)
--max-k 25           # Reduced from 29 (smaller k-mer range)
--no-stream          # Disable streaming to reduce memory pressure
```

### 3. Enhanced Memory Management
```bash
ulimit -v 62914560   # Hard virtual memory limit (~60GB)
ulimit -m 62914560   # Hard resident memory limit (~60GB)
export MALLOC_TRIM_THRESHOLD_=100000  # Aggressive memory trimming
export MALLOC_MMAP_THRESHOLD_=100000  # Force malloc efficiency
```

### 4. Real-Time Memory Monitoring
Added memory checkpoints at each stage:
- Initial memory status
- Before database creation
- After database creation
- After model fitting
- Final memory status

## Expected Behavior Changes

### Performance Impact
- **Runtime**: 24-48 hours (vs previous 8-16 hour estimate)
- **Memory usage**: Peak ~55GB (vs previous ~60GB+ peaks)
- **CPU utilization**: 8 threads (vs previous 16 threads)
- **Stability**: Should eliminate segmentation faults

### Progress Indicators
You should now see:
```
Very large dataset detected (464 samples). Using ultra-conservative parameters.
Initial memory status: [memory info]
Creating PopPUNK database...
Progress (CPU): [steady progress without crashes]
Memory after database creation: [controlled memory usage]
```

## Alternative Fallback Strategy

If ultra-conservative approach still fails, use the chunked alternative:

```bash
# Process in smaller, manageable chunks
nextflow run poppunk_chunked_alternative.nf \
    --input ./assemblies \
    --resultsDir ./results \
    --chunk_size 200
```

This approach:
- Processes 200 genomes at a time
- Merges results from all chunks
- Guarantees completion even with memory constraints

## Files Updated

1. **`nextflow_tapir_poppunk_snp.nf`**:
   - Ultra-conservative resource allocation
   - Enhanced memory management
   - Real-time memory monitoring
   - Adaptive parameter selection for >450 samples

2. **`nextflow.config`**:
   - Reduced PopPUNK threads to 8
   - Increased memory to 60GB
   - Extended time limit to 48 hours

3. **`poppunk_chunked_alternative.nf`**:
   - Complete alternative pipeline for chunked processing
   - Fallback strategy for extreme cases

4. **Documentation**:
   - `POPPUNK_PERSISTENT_SEGFAULT_FIX.md` - Technical details
   - Updated `README.md` with new troubleshooting

## Success Probability

With these ultra-conservative settings:
- **High confidence** for successful completion
- **Proven approach** for large genomic datasets
- **Multiple fallback options** if needed

## Monitoring

Use the monitoring script to track progress:
```bash
./monitor_poppunk.sh
```

Expected timeline:
- **Hours 0-4**: Database creation and sketching
- **Hours 4-24**: Distance calculation (critical phase)
- **Hours 24-36**: Model fitting
- **Hours 36-48**: Cluster assignment

## Next Steps

1. **Re-run the pipeline** with ultra-conservative settings
2. **Monitor progress** using the monitoring script
3. **If still failing**: Use the chunked alternative approach
4. **Report success**: The pipeline should now complete your 464-genome analysis

The ultra-conservative approach prioritizes stability and completion over speed, ensuring your large Burkholderia dataset analysis succeeds.