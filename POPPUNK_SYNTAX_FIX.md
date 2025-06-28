# PopPUNK Syntax Fix

## Error Encountered
```
poppunk: error: argument --fit-model: not allowed with argument --create-db
```

## Root Cause
The pipeline was trying to combine `--create-db` and `--fit-model` in a single PopPUNK command:

```bash
# BROKEN - These arguments cannot be used together
poppunk --create-db --r-files assembly_list.txt \
        --output poppunk_db \
        --fit-model bgmm \
        --overwrite
```

PopPUNK 2.7.5 does not allow `--fit-model` to be used with `--create-db` in the same command.

## Fix Applied

### Before (BROKEN):
```bash
# Single command trying to do both operations
poppunk --create-db --r-files assembly_list.txt \
        --output poppunk_db \
        --fit-model bgmm \
        --overwrite
```

### After (FIXED):
```bash
# Step 1: Create database only
poppunk --create-db --r-files assembly_list.txt \
        --output poppunk_db \
        --overwrite

# Step 2: Fit model separately
poppunk --fit-model bgmm \
        --ref-db poppunk_db \
        --output poppunk_fit \
        --overwrite
```

## Complete Fixed Workflow

The corrected PopPUNK workflow now consists of 4 separate steps:

### 1. Database Creation
```bash
poppunk --create-db --r-files assembly_list.txt \
        --output poppunk_db \
        --threads 32 \
        --overwrite
```

### 2. Model Fitting
```bash
poppunk --fit-model bgmm \
        --ref-db poppunk_db \
        --output poppunk_fit \
        --threads 32 \
        --overwrite
```

### 3. Quality Control (Optional)
```bash
poppunk --qc-db --ref-db poppunk_fit \
        --output qc_results \
        --threads 32 \
        --overwrite
```

### 4. Cluster Assignment
```bash
poppunk --assign-query --ref-db poppunk_fit \
        --q-files assembly_list.txt \
        --output poppunk_assigned \
        --threads 32 \
        --overwrite
```

## Key Changes Made

### 1. Separated Operations
- **Database creation** and **model fitting** are now separate steps
- Each step has its own input/output directories
- Proper reference database usage between steps

### 2. Correct Reference Usage
- Model fitting uses `--ref-db poppunk_db` (from step 1)
- QC uses `--ref-db poppunk_fit` (from step 2)
- Assignment uses `--ref-db poppunk_fit` (from step 2)

### 3. Enhanced Error Handling
- Each step can fail independently
- Clear progress reporting for each step
- Optional QC step that won't break the pipeline

## Files Updated

### Main Pipeline:
- `nextflow_tapir_poppunk_snp.nf` - Fixed PopPUNK command structure

### New Files:
- `test_poppunk_syntax.nf` - Test script to verify command syntax
- `fix_poppunk_syntax.sh` - Comprehensive fix and execution script
- `POPPUNK_SYNTAX_FIX.md` - This documentation

## How to Use the Fix

### 1. Test the Fixed Syntax
```bash
cd ~/nextflow_tapir_poppunk_snp
./fix_poppunk_syntax.sh test-syntax
```

### 2. Run with Fixed Commands
```bash
./fix_poppunk_syntax.sh run-fixed /path/to/input /path/to/output
```

### 3. Resume from Previous Failure
```bash
./fix_poppunk_syntax.sh resume /path/to/input /path/to/output
```

## Benefits of the Fix

### 1. **Correct Command Syntax**
- Eliminates the "not allowed with argument" error
- Uses proper PopPUNK command structure
- Compatible with PopPUNK 2.7.5

### 2. **Better Error Isolation**
- Each step can be debugged independently
- Clearer error messages for specific operations
- Easier troubleshooting

### 3. **Improved Reliability**
- Follows PopPUNK's intended workflow
- Reduces command complexity
- More stable execution

### 4. **Enhanced Monitoring**
- Progress reporting for each step
- Memory checkpoints between operations
- Clear success/failure indicators

## Validation

### Test Command Syntax:
```bash
./fix_poppunk_syntax.sh test-syntax
```

This will verify:
- ✅ `--create-db` syntax is valid
- ✅ `--fit-model` syntax is valid
- ✅ `--qc-db` syntax is valid
- ✅ `--assign-query` syntax is valid
- ❌ `--create-db --fit-model` combination is not allowed (expected)

## Troubleshooting

### If PopPUNK Still Fails:

1. **Check PopPUNK version compatibility**:
   ```bash
   docker run staphb/poppunk:2.7.5 poppunk --version
   ```

2. **Verify command syntax**:
   ```bash
   ./fix_poppunk_syntax.sh test-syntax
   ```

3. **Check input files**:
   ```bash
   ls -la /path/to/input/*.{fasta,fa,fas}
   ```

4. **Review logs**:
   ```bash
   cat .nextflow.log
   ```

## Summary

✅ **Fixed the PopPUNK syntax error**  
✅ **Separated database creation and model fitting**  
✅ **Improved workflow reliability**  
✅ **Enhanced error handling and monitoring**  
✅ **Maintained all original functionality**  

The pipeline now uses the correct PopPUNK command structure and should run without the "not allowed with argument --create-db" error.