# Quick Fix - File Matching Issues

## 🚨 Problem Fixed
```
WARN: Could not find assembly file for taxon: GCA_963561215_1
WARN: Could not find assembly file for taxon: GCA_963566695_1
WARN: Could not find assembly file for taxon: Burkholderia_pseudomallei_ABCPW_107_GCF_000773235_1_Australia
```

## ✅ Solution Applied
**Enhanced file matching with 4 progressive strategies**

### Matching Strategies:
1. **Exact Match**: `taxon_name == file_basename`
2. **Variant Match**: `GCA_123_1` ↔ `GCA.123.1` (underscores ↔ dots)
3. **Partial Match**: substring matching
4. **Fuzzy Match**: ignore GCF/GCA suffixes

## 🚀 Quick Commands

### Resume Your Failed Pipeline:
```bash
cd ~/nextflow_tapir_poppunk_snp
./fix_file_matching.sh resume /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_322_genomes_poppunk
```

### Test the Enhanced Matching:
```bash
./fix_file_matching.sh test
```

### Run Fresh with Enhanced Matching:
```bash
./fix_file_matching.sh run /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_enhanced
```

## 🔧 What Was Enhanced

### Before (BROKEN):
- Only exact basename matching
- Failed on underscore/dot differences
- Many "Could not find assembly file" warnings

### After (ENHANCED):
- 4 progressive matching strategies
- Handles naming convention differences
- Detailed logging of successful matches

## 🎯 Expected Success

When working, you'll see:
```
✅ Successfully matched (exact): sample1 -> sample1.fasta (cluster 1)
✅ Successfully matched (variant): GCA_963561215_1 -> GCA.963561215.1.fasta (cluster 2)
✅ Successfully matched (partial): long_name -> short.fasta (cluster 3)
✅ Successfully matched (fuzzy): complex_GCF_123 -> simple.fasta (cluster 4)
```

**Your pipeline should now successfully match most files and eliminate the warnings!**