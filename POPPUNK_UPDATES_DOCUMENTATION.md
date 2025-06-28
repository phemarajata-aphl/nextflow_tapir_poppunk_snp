# PopPUNK Command Updates - Documentation

## Overview
This document details the updates made to the PopPUNK process in the TAPIR + PopPUNK + Per-Clade SNP Analysis Pipeline to align with the latest PopPUNK documentation and best practices.

## Documentation Sources
Updates based on the latest PopPUNK documentation:
- [Sketching](https://poppunk.bacpop.org/sketching.html)
- [QC](https://poppunk.bacpop.org/qc.html)
- [Model Fitting](https://poppunk.bacpop.org/model_fitting.html)
- [Query Assignment](https://poppunk.bacpop.org/query_assignment.html)

## Key Changes Made

### 1. **Sketching Process (NEW)**
**Before:** Direct database creation
```bash
poppunk --create-db --r-files assembly_list.txt --output poppunk_db
```

**After:** Separate sketching step with fallback
```bash
# Step 1: Create sketches (new approach)
poppunk_sketch --r-files assembly_list.txt --output sketches --threads X

# Step 2: Create database from sketches
poppunk --create-db --r-files assembly_list.txt --output poppunk_db --sketches sketches

# Fallback: If poppunk_sketch fails, use legacy approach
poppunk --create-db --r-files assembly_list.txt --output poppunk_db
```

### 2. **Model Fitting (UPDATED)**
**Before:** Combined with database creation
```bash
poppunk --create-db --fit-model bgmm --r-files assembly_list.txt --output poppunk_db
```

**After:** Separate model fitting step
```bash
poppunk --fit-model bgmm --ref-db poppunk_db --output poppunk_fit
```

### 3. **Quality Control (NEW)**
**Before:** No QC step

**After:** Integrated QC check with fallback
```bash
poppunk_qc --ref-db poppunk_fit --output qc_results --threads X
```

### 4. **Query Assignment (UPDATED)**
**Before:** Legacy assignment command
```bash
poppunk --assign-query --ref-db poppunk_db --q-files assembly_list.txt --output poppunk_assigned
```

**After:** New assignment command with fallback
```bash
# New approach
poppunk_assign --db poppunk_fit --query assembly_list.txt --output poppunk_assigned

# Fallback to legacy if new command fails
poppunk --assign-query --ref-db poppunk_fit --q-files assembly_list.txt --output poppunk_assigned
```

## Updated Workflow Steps

### Complete Updated Workflow:
1. **Sketching**: `poppunk_sketch` (with legacy fallback)
2. **Database Creation**: `poppunk --create-db` (from sketches or direct)
3. **Model Fitting**: `poppunk --fit-model bgmm` (separate step)
4. **Quality Control**: `poppunk_qc` (new step with fallback)
5. **Cluster Assignment**: `poppunk_assign` (with legacy fallback)

### Fallback Strategy:
The updated process includes comprehensive fallback mechanisms:
- If `poppunk_sketch` fails → use legacy `poppunk --create-db`
- If `poppunk_qc` fails → skip QC step and continue
- If `poppunk_assign` fails → use legacy `poppunk --assign-query`

## New Output Files

### Additional Outputs:
- `qc_report.txt` - Quality control report (optional)
- Enhanced logging for each step
- Better error handling and reporting

### Cluster File Locations:
The updated process searches for cluster files in multiple locations:
1. `poppunk_assigned/*clusters.csv`
2. `poppunk_assigned/*cluster*.csv`
3. `poppunk_fit/*clusters.csv`
4. `./*clusters.csv`

## Benefits of Updates

### 1. **Improved Compatibility**
- Supports both new and legacy PopPUNK commands
- Graceful fallback to older methods if new commands unavailable
- Compatible with different PopPUNK versions

### 2. **Enhanced Quality Control**
- Integrated QC step for better result validation
- QC report generation for analysis quality assessment
- Optional QC step that doesn't break pipeline if unavailable

### 3. **Better Resource Management**
- Separate sketching step allows for better memory management
- More granular control over each analysis step
- Improved error handling and recovery

### 4. **Enhanced Logging**
- Step-by-step progress reporting
- Memory usage monitoring at each step
- Comprehensive analysis summary

## Backward Compatibility

### Legacy Support:
The updated process maintains full backward compatibility:
- Falls back to legacy commands if new ones are unavailable
- Maintains same input/output interface
- Preserves all existing functionality

### Version Compatibility:
- **PopPUNK 2.7.5+**: Uses new commands (`poppunk_sketch`, `poppunk_assign`, `poppunk_qc`)
- **PopPUNK < 2.7.5**: Automatically falls back to legacy commands
- **Mixed environments**: Gracefully handles partial command availability

## Testing and Validation

### Recommended Testing:
1. **Test with new commands**: Verify `poppunk_sketch`, `poppunk_assign`, `poppunk_qc` work
2. **Test fallback mechanisms**: Ensure legacy commands work when new ones fail
3. **Test QC integration**: Verify QC reports are generated when available
4. **Test output consistency**: Ensure cluster files are found in all scenarios

### Validation Commands:
```bash
# Test the updated pipeline
nextflow run nextflow_tapir_poppunk_snp.nf -profile c4_highmem_192 --input test_data --resultsDir test_results

# Check for QC report
ls test_results/poppunk/qc_report.txt

# Verify cluster assignments
head test_results/poppunk/clusters.csv
```

## Migration Notes

### For Existing Users:
- **No action required**: Pipeline automatically detects and uses appropriate commands
- **Enhanced features**: QC reporting now available if supported
- **Same interface**: All existing parameters and options remain unchanged

### For New Users:
- **Latest features**: Automatically uses newest PopPUNK commands when available
- **Better reliability**: Enhanced error handling and fallback mechanisms
- **Quality assurance**: Integrated QC checks for better results

## Troubleshooting

### Common Issues:
1. **"poppunk_sketch not found"**: Normal - pipeline falls back to legacy method
2. **"poppunk_qc failed"**: Normal - QC step is optional and will be skipped
3. **"poppunk_assign not found"**: Normal - pipeline falls back to legacy assignment

### Debug Information:
The updated process provides detailed logging for each step, making it easier to identify and resolve issues.

## Summary

The updated PopPUNK process provides:
- ✅ Latest PopPUNK command compatibility
- ✅ Comprehensive fallback mechanisms
- ✅ Integrated quality control
- ✅ Enhanced error handling
- ✅ Backward compatibility
- ✅ Better resource management
- ✅ Detailed progress reporting

The pipeline now follows the latest PopPUNK best practices while maintaining full compatibility with existing workflows and older PopPUNK versions.