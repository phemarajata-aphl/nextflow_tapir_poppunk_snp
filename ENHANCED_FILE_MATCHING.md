# Enhanced File Matching Solution

## Problem Identified
The pipeline was generating numerous warnings like:
```
WARN: Could not find assembly file for taxon: GCA_963561215_1
WARN: Could not find assembly file for taxon: Burkholderia_pseudomallei_ABCPW_107_GCF_000773235_1_Australia
```

## Root Cause Analysis
The issue occurred because PopPUNK creates taxon names that don't exactly match the actual FASTA file names. Common mismatches include:

1. **Underscore vs Dot**: `GCA_963561215_1` vs `GCA.963561215.1`
2. **Different naming conventions**: Long descriptive names vs short accession numbers
3. **File extensions**: Taxon names may or may not include file extensions
4. **Hyphen vs Underscore**: Different punctuation in file names

## Enhanced Matching Solution

### Multiple Matching Strategies
The enhanced pipeline now uses 4 progressive matching strategies:

#### Strategy 1: Exact Basename Match
```groovy
// Direct exact match
file_basename == taxon_name
```

#### Strategy 2: Variant Matching
```groovy
// Create variants for both taxon and file names
taxon_variants = [
    base_name,
    base_name.replaceAll('_', '.'),   // GCA_123_1 → GCA.123.1
    base_name.replaceAll('\\.', '_'), // GCA.123.1 → GCA_123_1
    base_name.replaceAll('-', '_'),   // GCA-123-1 → GCA_123_1
    base_name.replaceAll('_', '-')    // GCA_123_1 → GCA-123-1
]
```

#### Strategy 3: Partial Matching
```groovy
// Check if either name contains the other
file_basename.contains(variant) || variant.contains(file_basename)
```

#### Strategy 4: Fuzzy Matching
```groovy
// Remove common suffixes and try matching
simplified_taxon = base_name.replaceAll(/_GCF_.*/, '').replaceAll(/_GCA_.*/, '')
simplified_file = file_basename.replaceAll(/_GCF_.*/, '').replaceAll(/_GCA_.*/, '')
```

## Implementation Details

### Enhanced Workflow Logic
```groovy
// Create comprehensive file information
all_assembly_files = Channel.fromPath("${params.input}/*.{fasta,fa,fas}")
    .map { file -> 
        def basename = file.baseName
        def name_variants = [
            basename,
            basename.replaceAll('_', '.'),
            basename.replaceAll('\\.', '_'),
            basename.replaceAll('-', '_'),
            basename.replaceAll('_', '-')
        ]
        return tuple(file, basename, name_variants)
    }
    .collect()

// Enhanced matching with multiple strategies
cluster_assignments = clusters_csv
    .splitCsv(header: true)
    .combine(all_assembly_files)
    .map { row, assembly_files -> 
        // Progressive matching strategies
        // ... (detailed implementation in pipeline)
    }
```

### Match Strategy Logging
The pipeline now logs which strategy was successful:
```
Successfully matched (exact): sample1 -> sample1.fasta (cluster 1)
Successfully matched (variant): GCA_123_1 -> GCA.123.1.fasta (cluster 2)
Successfully matched (partial): long_name -> short_name.fasta (cluster 3)
Successfully matched (fuzzy): complex_name_GCF_123 -> simple_name.fasta (cluster 4)
```

## Benefits of Enhanced Matching

### 1. **Higher Success Rate**
- Handles common naming convention differences
- Reduces "Could not find assembly file" warnings
- Increases the number of successfully matched samples

### 2. **Multiple Fallback Strategies**
- If exact matching fails, tries variant matching
- If variant matching fails, tries partial matching
- If partial matching fails, tries fuzzy matching

### 3. **Detailed Logging**
- Shows which strategy was successful for each match
- Helps debug remaining unmatched files
- Provides insights into naming patterns

### 4. **Robust Error Handling**
- Gracefully handles unmatched files
- Continues processing with successfully matched files
- Provides detailed debug information for troubleshooting

## Expected Improvements

### Before Enhancement:
```
WARN: Could not find assembly file for taxon: GCA_963561215_1
WARN: Could not find assembly file for taxon: GCA_963566695_1
WARN: Could not find assembly file for taxon: GCA_963562965_1
... (many more warnings)
```

### After Enhancement:
```
Successfully matched (variant): GCA_963561215_1 -> GCA.963561215.1.fasta (cluster 1)
Successfully matched (variant): GCA_963566695_1 -> GCA.963566695.1.fasta (cluster 2)
Successfully matched (variant): GCA_963562965_1 -> GCA.963562965.1.fasta (cluster 3)
... (successful matches)
```

## Usage

### Test the Enhanced Matching
```bash
cd ~/nextflow_tapir_poppunk_snp
./fix_file_matching.sh test
```

### Resume Your Failed Pipeline
```bash
./fix_file_matching.sh resume /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_322_genomes_poppunk
```

### Run Fresh with Enhanced Matching
```bash
./fix_file_matching.sh run /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_enhanced
```

## Troubleshooting

### If Some Files Still Don't Match:
1. **Check the debug output**: Look for the specific taxon names that still fail
2. **Examine file naming patterns**: Compare taxon names with actual file names
3. **Add custom matching logic**: Extend the fuzzy matching for specific patterns

### Common Remaining Issues:
- **Completely different naming schemes**: May require manual mapping
- **Missing files**: Some taxon names may not have corresponding files
- **Complex transformations**: May need additional variant generation

## Files Updated

### Main Pipeline:
- `nextflow_tapir_poppunk_snp.nf` - Enhanced file matching logic

### New Files:
- `fix_file_matching.sh` - Enhanced matching execution script
- `debug_file_matching.nf` - Debug analysis script
- `ENHANCED_FILE_MATCHING.md` - This documentation

## Summary

✅ **Multiple matching strategies** - 4 progressive approaches to find matches  
✅ **Variant handling** - Automatic conversion between underscores, dots, hyphens  
✅ **Partial matching** - Handles substring relationships  
✅ **Fuzzy matching** - Ignores common suffixes like GCF/GCA identifiers  
✅ **Detailed logging** - Shows which strategy worked for each match  
✅ **Robust error handling** - Graceful handling of unmatched files  

The enhanced file matching should significantly reduce the "Could not find assembly file" warnings and increase the number of successfully processed samples in your pipeline!