# Quick Fix Guide

## The Problems
1. **Multi-channel output error** - POPPUNK process has multiple outputs but workflow expects single output
2. **Input file detection error** - Pipeline can't find FASTA files in the specified directory

## The Solutions

### ✅ Problem 1: FIXED
Updated the workflow to properly handle POPPUNK's multiple outputs:
```groovy
// Extract outputs correctly
poppunk_results = POPPUNK(assemblies_ch)
clusters_csv = poppunk_results[0]  // clusters.csv
qc_report = poppunk_results[1]     // qc_report.txt (optional)
```

### 🔍 Problem 2: NEEDS INVESTIGATION
The input directory issue needs to be debugged on your system.

## What to Do Next

### Step 1: Debug the Input Directory
```bash
cd ~/nextflow_tapir_poppunk_snp
./fix_pipeline_errors.sh debug-input /mnt/disks/ngs-data/subset_100
```

This will tell you:
- Does the directory exist?
- What files are actually there?
- What file extensions are present?

### Step 2: Run the Fixed Pipeline
Once you confirm the input directory is correct:
```bash
./fix_pipeline_errors.sh run-fixed /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_322_genomes_poppunk
```

## Common Input Issues & Solutions

### Issue: Directory doesn't exist
**Check:** `ls -la /mnt/disks/ngs-data/subset_100`
**Solution:** Verify the correct path

### Issue: Files have different extensions
**Check:** `ls /mnt/disks/ngs-data/subset_100 | head -5`
**Solution:** Rename files or update the pattern

### Issue: Files exist but wrong extensions
**Example:** Files are `.fna` instead of `.fasta`
**Solution:** 
```bash
cd /mnt/disks/ngs-data/subset_100
for file in *.fna; do mv "$file" "${file%.fna}.fasta"; done
```

## Quick Test
If you want to test with a small dataset first:
```bash
# Create test data
mkdir -p test_data
# Copy 3-5 FASTA files to test_data/
./fix_pipeline_errors.sh run-fixed test_data test_results
```

The multi-channel output error is now fixed. The remaining issue is just making sure the input files are accessible with the correct extensions!