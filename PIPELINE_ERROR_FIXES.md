# Pipeline Error Fixes

## Issues Encountered

### 1. Multi-channel Output Error
**Error Message:**
```
Multi-channel output cannot be applied to operator splitCsv for which argument is already provided
```

**Root Cause:**
The POPPUNK process was updated to have multiple outputs:
```groovy
output:
path 'clusters.csv'
path 'qc_report.txt', optional: true
```

But the workflow was still trying to use `splitCsv` directly on the process output, which now returns a tuple instead of a single file.

**Fix Applied:**
```groovy
// Before (BROKEN):
clusters_csv = POPPUNK(assemblies_ch)
cluster_assignments = clusters_csv.splitCsv(header: true)

// After (FIXED):
poppunk_results = POPPUNK(assemblies_ch)
clusters_csv = poppunk_results[0]  // First output is clusters.csv
qc_report = poppunk_results[1]     // Second output is qc_report.txt (optional)
cluster_assignments = clusters_csv.splitCsv(header: true)
```

### 2. Input File Detection Error
**Error Message:**
```
No FASTA files found in /mnt/disks/ngs-data/subset_100
```

**Root Cause:**
- Input directory may not exist in the current environment
- FASTA files may have different extensions than expected
- File permissions or path issues

**Fix Applied:**
Enhanced input debugging with better error messages:
```groovy
// Added debugging information
log.info "Looking for FASTA files in: ${params.input}"
log.info "Search pattern: ${params.input}/*.{fasta,fa,fas}"

assemblies_ch = Channel.fromPath("${params.input}/*.{fasta,fa,fas}")
    .ifEmpty { 
        log.error "No FASTA files found in ${params.input}"
        log.error "Checked extensions: .fasta, .fa, .fas"
        log.error "Please verify the input directory exists and contains FASTA files"
        error "No FASTA files found in ${params.input}" 
    }
    .collect()
```

## Files Created/Updated

### Updated Files:
- `nextflow_tapir_poppunk_snp.nf` - Fixed multi-channel output and enhanced input debugging

### New Files:
- `fix_pipeline_errors.sh` - Script to diagnose and fix pipeline errors
- `debug_input.nf` - Debug script for input directory issues
- `PIPELINE_ERROR_FIXES.md` - This documentation

## How to Use the Fixes

### 1. Debug Input Directory Issues
```bash
./fix_pipeline_errors.sh debug-input /mnt/disks/ngs-data/subset_100
```

This will:
- Check if the directory exists
- Look for FASTA files with supported extensions
- Show what files are actually present
- Analyze file extensions in the directory

### 2. Run the Fixed Pipeline
```bash
./fix_pipeline_errors.sh run-fixed /path/to/input /path/to/output
```

This will:
- Validate the input directory
- Check for FASTA files
- Run the pipeline with the fixes applied
- Provide helpful error messages if issues persist

### 3. Test with Small Dataset
```bash
# Create test data first
mkdir -p test_data
# Copy some FASTA files to test_data/

# Then test
./fix_pipeline_errors.sh run-fixed test_data test_results
```

## Common Input Directory Issues

### Issue 1: Directory Doesn't Exist
**Solution:** Verify the correct path to your input directory
```bash
ls -la /mnt/disks/ngs-data/subset_100
```

### Issue 2: Wrong File Extensions
**Supported extensions:** `.fasta`, `.fa`, `.fas`

**Check what extensions you have:**
```bash
ls /path/to/input | sed 's/.*\.//' | sort | uniq -c
```

**Rename files if needed:**
```bash
# Example: rename .fna to .fasta
for file in *.fna; do mv "$file" "${file%.fna}.fasta"; done
```

### Issue 3: File Permissions
**Solution:** Ensure files are readable
```bash
chmod 644 /path/to/input/*.fasta
```

## Verification Steps

### 1. Check Pipeline Syntax
```bash
nextflow run nextflow_tapir_poppunk_snp.nf --help
```

### 2. Test with Debug Script
```bash
nextflow run debug_input.nf --input /path/to/your/data
```

### 3. Run with Enhanced Logging
```bash
nextflow run nextflow_tapir_poppunk_snp.nf -profile c4_highmem_192 --input /path/to/input --resultsDir /path/to/output -with-trace -with-report
```

## Summary of Fixes

✅ **Multi-channel Output**: Fixed POPPUNK process output handling
✅ **Input Debugging**: Enhanced error messages for file detection
✅ **File Pattern Matching**: Improved FASTA file detection
✅ **Error Diagnostics**: Added comprehensive debugging tools
✅ **User-Friendly Scripts**: Created helper scripts for troubleshooting

The pipeline should now work correctly with proper input directories containing FASTA files with supported extensions (.fasta, .fa, .fas).