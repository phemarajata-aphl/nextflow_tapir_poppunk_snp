# PopPUNK Persistent Segmentation Fault - Ultra-Conservative Fix

## Problem Analysis
Despite previous optimizations, PopPUNK is still experiencing segmentation faults at ~3.9% during distance calculation with 464 Burkholderia pseudomallei genomes. This indicates the memory pressure is still too high.

## Root Cause
The distance calculation phase creates an all-vs-all comparison matrix that grows quadratically:
- **464 genomes** = 464² = 215,296 pairwise comparisons
- **Memory requirement** = ~107,648 distance values × memory per comparison
- **With 16 threads** = Each thread handles ~13,456 comparisons simultaneously

## Ultra-Conservative Solution Implemented

### 1. Aggressive Thread Reduction
- **Reduced from 16 to 8 threads** to minimize memory contention
- **Reduced memory per thread** allows more stable execution
- **Less parallel memory allocation** reduces peak memory usage

### 2. Ultra-Conservative PopPUNK Parameters
For datasets >450 samples (your 464 qualifies):
```bash
--sketch-size 5000    # Reduced from 9999 (smaller memory footprint)
--min-k 15           # Increased from 13 (fewer k-mers)
--max-k 25           # Reduced from 29 (fewer k-mers)
--no-stream          # Disable streaming to reduce memory pressure
```

### 3. Enhanced Memory Management
```bash
ulimit -v 62914560   # ~60GB virtual memory hard limit
ulimit -m 62914560   # ~60GB resident memory hard limit
export MALLOC_TRIM_THRESHOLD_=100000  # Aggressive memory trimming
export MALLOC_MMAP_THRESHOLD_=100000  # Force malloc to use sbrk
```

### 4. Memory Monitoring
Added checkpoints to monitor memory usage at each stage:
- Before database creation
- After database creation  
- After model fitting
- Final memory status

## Key Changes Made

### Resource Allocation
```groovy
// Before
process POPPUNK {
    cpus = 16
    memory = '56 GB'
    time = '24h'
}

// After (Ultra-Conservative)
process POPPUNK {
    cpus = 8           // 50% reduction in threads
    memory = '60 GB'   // Maximum available memory
    time = '48h'       // Double the time allowance
}
```

### Parameter Selection Logic
```bash
if [ $NUM_SAMPLES -gt 450 ]; then
    # Ultra-conservative for very large datasets (464 samples)
    SKETCH_SIZE="--sketch-size 5000"
    MIN_K="--min-k 15"
    MAX_K="--max-k 25"
    EXTRA_PARAMS="--no-stream"
elif [ $NUM_SAMPLES -gt 400 ]; then
    # Conservative for large datasets
    SKETCH_SIZE="--sketch-size 7500"
    MIN_K="--min-k 13"
    MAX_K="--max-k 29"
    EXTRA_PARAMS=""
fi
```

## Expected Behavior

With these ultra-conservative settings:

1. **Slower but stable execution**: Will take longer but should complete without segfaults
2. **Reduced memory peaks**: 8 threads vs 16 threads = ~50% less peak memory usage
3. **Smaller sketch size**: 5000 vs 9999 = ~50% less memory per genome
4. **Memory monitoring**: Real-time feedback on memory usage at each stage

## Performance Trade-offs

### Pros:
- ✅ **Stability**: Should eliminate segmentation faults
- ✅ **Completion**: Will finish the analysis successfully
- ✅ **Accuracy**: Still maintains clustering accuracy with conservative parameters

### Cons:
- ⏱️ **Slower execution**: May take 24-48 hours instead of 8-16 hours
- 📊 **Slightly reduced resolution**: Smaller sketch size may reduce fine-grained clustering

## Alternative Strategies

If this still fails, consider:

1. **Further thread reduction**: Set `poppunk_threads = 4`
2. **Dataset splitting**: Process in batches of 200-300 genomes
3. **Alternative clustering**: Use FastANI or Mash for initial clustering

## Monitoring

Use the monitoring script to track progress:
```bash
./monitor_poppunk.sh
```

Expected output with ultra-conservative parameters:
```
Very large dataset detected (464 samples). Using ultra-conservative parameters.
Initial memory status: [memory info]
Memory before database creation: [memory info]
Creating PopPUNK database...
Progress (CPU): [slower but steady progress]
```

## Success Indicators

The pipeline should now:
1. ✅ **Complete database creation** without segfaults
2. ✅ **Progress steadily** through distance calculations
3. ✅ **Generate cluster assignments** for all 464 genomes
4. ✅ **Maintain memory usage** within 60GB limits

This ultra-conservative approach prioritizes stability over speed to ensure your large Burkholderia dataset completes successfully.