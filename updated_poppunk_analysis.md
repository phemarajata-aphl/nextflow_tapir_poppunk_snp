# PopPUNK Command Updates Analysis

Based on the latest PopPUNK documentation, here are the key changes needed:

## Current Commands in Pipeline:
1. `poppunk --create-db --r-files assembly_list.txt --output poppunk_db --threads X --fit-model bgmm`
2. `poppunk --assign-query --ref-db poppunk_db --q-files assembly_list.txt --output poppunk_assigned`

## Documentation Analysis:

### 1. Sketching (Database Creation)
**Current:** `--create-db --r-files`
**Latest:** Should use `poppunk_sketch` for initial sketching, then `poppunk` for database creation

### 2. Model Fitting  
**Current:** `--fit-model bgmm` combined with `--create-db`
**Latest:** Should be separate step after database creation

### 3. Query Assignment
**Current:** `--assign-query --q-files`
**Latest:** Should use `poppunk_assign` command instead of `poppunk --assign-query`

### 4. QC Integration
**Current:** No QC step
**Latest:** Should include `poppunk_qc` for quality control

## Recommended Updated Workflow:

1. **Sketch Creation:** `poppunk_sketch --r-files assembly_list.txt --output sketches`
2. **Database Creation:** `poppunk --create-db --r-files assembly_list.txt --output poppunk_db`  
3. **Model Fitting:** `poppunk --fit-model bgmm --ref-db poppunk_db --output poppunk_fit`
4. **QC Check:** `poppunk_qc --ref-db poppunk_fit --output qc_results`
5. **Assignment:** `poppunk_assign --db poppunk_fit --query assembly_list.txt --output assignments`

## Key Changes Needed:
- Replace `poppunk --assign-query` with `poppunk_assign`
- Add separate sketching step with `poppunk_sketch`
- Add QC step with `poppunk_qc`
- Separate model fitting from database creation
- Update parameter names and structure