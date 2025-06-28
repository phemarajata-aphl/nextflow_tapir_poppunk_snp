# Quick Fix Reference

## 🚨 Error Fixed
```
poppunk: error: argument --fit-model: not allowed with argument --create-db
```

## ✅ Solution Applied
**Separated the combined command into individual steps:**

### Before (BROKEN):
```bash
poppunk --create-db --fit-model bgmm  # ❌ Not allowed
```

### After (FIXED):
```bash
poppunk --create-db                   # ✅ Step 1
poppunk --fit-model bgmm --ref-db     # ✅ Step 2
```

## 🚀 Quick Commands

### Test the Fix:
```bash
cd ~/nextflow_tapir_poppunk_snp
./fix_poppunk_syntax.sh test-syntax
```

### Resume Your Failed Pipeline:
```bash
./fix_poppunk_syntax.sh resume /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_322_genomes_poppunk
```

### Run Fresh with Fixed Commands:
```bash
./fix_poppunk_syntax.sh run-fixed /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_fixed
```

## 🔧 What Changed

**New PopPUNK Workflow (4 steps):**
1. **Database Creation**: `poppunk --create-db`
2. **Model Fitting**: `poppunk --fit-model --ref-db`
3. **Quality Control**: `poppunk --qc-db --ref-db` (optional)
4. **Cluster Assignment**: `poppunk --assign-query --ref-db`

## 📁 Files Modified
- ✅ `nextflow_tapir_poppunk_snp.nf` - Fixed PopPUNK commands
- ➕ `fix_poppunk_syntax.sh` - Fix execution script
- ➕ `test_poppunk_syntax.nf` - Syntax validation script

## 🎯 Expected Result
When working correctly, you'll see:
```
✅ Step 1: Database creation: Completed
✅ Step 2: Model fitting: Completed  
✅ Step 3: QC check: Completed (or Skipped)
✅ Step 4: Cluster assignment: Completed
🎉 SUCCESS: PopPUNK syntax fix worked!
```

**The pipeline should now run without the PopPUNK syntax error!**