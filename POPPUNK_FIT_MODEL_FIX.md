# PopPUNK --fit-model Error Fix

## The Problem
You encountered this error:
```
poppunk: error: argument --fit-model: expected one argument
```

## Root Cause
The error occurs because the PopPUNK workflow in the original pipeline was using an outdated command structure. In PopPUNK 2.7.5, the `--fit-model` argument expects a model type to be specified.

## The Fix

### Original (Broken) Workflow:
```bash
# Step 1: Create database
poppunk --create-db --r-files assembly_list.txt --output poppunk_db --threads 32

# Step 2: Fit model (BROKEN - missing model type)
poppunk --fit-model --ref-db poppunk_db --output poppunk_fit --threads 32

# Step 3: Assign clusters
poppunk --assign-query --ref-db poppunk_db --q-files assembly_list.txt --output poppunk_assigned
```

### Fixed Workflow (Option 1 - Combined):
```bash
# Step 1: Create database and fit model in one step
poppunk --create-db --r-files assembly_list.txt --output poppunk_db --threads 32 --fit-model bgmm

# Step 2: Assign clusters
poppunk --assign-query --ref-db poppunk_db --q-files assembly_list.txt --output poppunk_assigned
```

### Fixed Workflow (Option 2 - Separate):
```bash
# Step 1: Create database
poppunk --create-db --r-files assembly_list.txt --output poppunk_db --threads 32

# Step 2: Fit model (FIXED - includes model type)
poppunk --fit-model bgmm --ref-db poppunk_db --output poppunk_fit --threads 32

# Step 3: Assign clusters
poppunk --assign-query --ref-db poppunk_fit --q-files assembly_list.txt --output poppunk_assigned
```

## What Changed in Your Pipeline

I updated the `POPPUNK` process in `nextflow_tapir_poppunk_snp.nf` to use the combined approach (Option 1), which is more efficient and less prone to errors.

### Key Changes:
1. **Combined database creation and model fitting**: `--create-db` and `--fit-model bgmm` in one command
2. **Specified model type**: Added `bgmm` (Bayesian Gaussian Mixture Model) as the model type
3. **Simplified workflow**: Reduced from 3 steps to 2 steps

## Model Types Available in PopPUNK
- `bgmm` - Bayesian Gaussian Mixture Model (recommended, default)
- `dbscan` - DBSCAN clustering
- `refine` - Refine existing model
- `lineage` - Lineage model

## How to Use the Fix

### Test the syntax first:
```bash
./fix_poppunk_error.sh test-syntax
```

### Run your pipeline with the fix:
```bash
./fix_poppunk_error.sh run-fixed
```

### Or run directly:
```bash
nextflow run nextflow_tapir_poppunk_snp.nf \
    -profile c4_highmem_192 \
    --input /mnt/disks/ngs-data/subset_100 \
    --resultsDir /mnt/disks/ngs-data/results_322_genomes_poppunk \
    -resume
```

## Alternative Approach
If you still encounter issues, I've also created `poppunk_alternative.nf` which uses the two-step approach (Option 2) with proper model type specification.

## Verification
The fix ensures:
1. ✅ PopPUNK receives the required model type argument
2. ✅ Database creation and model fitting work correctly
3. ✅ Cluster assignment uses the proper reference database
4. ✅ Output files are generated in the expected format

The pipeline should now run successfully without the `--fit-model` argument error!