# Nextflow Workflow Error Fix

## Error Encountered
```
ERROR ~ Invalid method invocation `call` with arguments: [[Taxon:Burkholderia_pseudomallei_ABCPW_30_GCF_000774495_1_Australia, Cluster:1], /mnt/disks/ngs-data/subset_100/IP-0011-7_S2_L001-SPAdes.fasta, ...]
```

## Root Cause
The error occurred due to problematic channel operations in the workflow section. Specifically, the issue was with the `.combine()` operation that was creating complex nested data structures that Nextflow couldn't properly handle.

### Problematic Code:
```groovy
// BROKEN - Complex channel operations causing 'call' method error
all_assembly_files = Channel.fromPath("${params.input}/*.{fasta,fa,fas}")
    .collect()

individual_samples = clusters_csv
    .splitCsv(header: true)
    .combine(all_assembly_files)  // This creates problematic nested structures
    .map { row, assembly_files -> 
        // Complex mapping logic that fails
    }
```

## Fix Applied

### 1. **Simplified Channel Operations**
Removed the problematic `.combine()` operation and simplified the workflow logic:

```groovy
// FIXED - Simplified approach without .combine()
cluster_assignments = clusters_csv
    .splitCsv(header: true)
    .map { row -> 
        // Direct file matching without complex channel operations
        def taxon_name = row.Taxon ?: row.taxon ?: row.Sample ?: row.sample ?: row.ID ?: row.id
        def cluster_id = row.Cluster ?: row.cluster ?: row.cluster_id
        
        // Try to find the assembly file with different extensions
        def assembly_file = null
        def base_name = taxon_name.toString().replaceAll(/\.(fasta|fa|fas)$/, '')
        
        ['fasta', 'fa', 'fas'].each { ext ->
            if (!assembly_file) {
                def candidate = file("${params.input}/${base_name}.${ext}")
                if (candidate.exists()) {
                    assembly_file = candidate
                }
            }
        }
        
        if (!assembly_file) {
            log.warn "Could not find assembly file for taxon: ${taxon_name}"
            return null
        }
        
        return tuple(base_name, assembly_file, cluster_id.toString())
    }
    .filter { it != null }
```

### 2. **Fixed Variable Naming**
Updated variable names to avoid conflicts:

```groovy
// Before (confusing variable names):
cluster_assignments = individual_samples.map { ... }

// After (clear variable names):
cluster_gff_assignments = cluster_assignments.map { ... }
```

### 3. **Enhanced Error Handling**
- Better file matching logic
- Clearer error messages
- Graceful handling of missing files

## Key Changes Made

### 1. **Removed Complex Channel Operations**
- ❌ `.combine(all_assembly_files)` (caused nested structure issues)
- ✅ Direct file matching using `file()` function

### 2. **Simplified Data Flow**
- **Before**: CSV → combine with files → complex mapping → grouping
- **After**: CSV → direct file matching → simple tuple creation → grouping

### 3. **Better File Matching**
- Uses `file()` function to check file existence
- Tries multiple file extensions (.fasta, .fa, .fas)
- Handles missing files gracefully

### 4. **Clearer Variable Names**
- `individual_samples` → `cluster_assignments`
- `cluster_assignments` → `cluster_gff_assignments`

## Files Updated

### Main Pipeline:
- `nextflow_tapir_poppunk_snp.nf` - Fixed workflow section

### New Files:
- `fix_workflow_error.sh` - Fix execution script
- `WORKFLOW_ERROR_FIX.md` - This documentation

## How to Use the Fix

### 1. Test the Fixed Workflow
```bash
cd ~/nextflow_tapir_poppunk_snp
./fix_workflow_error.sh test
```

### 2. Resume Your Failed Pipeline
```bash
./fix_workflow_error.sh resume /path/to/input /path/to/output
```

### 3. Run Fresh with Fixed Workflow
```bash
./fix_workflow_error.sh run /path/to/input /path/to/output
```

## Why This Fix Works

### 1. **Eliminates Complex Channel Operations**
The `.combine()` operation was creating nested data structures that Nextflow couldn't properly handle, leading to the "Invalid method invocation `call`" error.

### 2. **Direct File Access**
Instead of combining channels and then mapping, the fix directly accesses files using the `file()` function, which is more reliable and easier to debug.

### 3. **Simplified Data Flow**
The new approach creates a straightforward data flow:
1. Read CSV rows
2. Extract taxon name and cluster ID
3. Find corresponding assembly file
4. Create simple tuple (name, file, cluster)

### 4. **Better Error Recovery**
- Missing files are handled gracefully with warnings
- Null entries are filtered out
- Clear logging for successful matches

## Expected Behavior

When working correctly, you should see:
```
✅ Successfully matched: sample1 -> sample1.fasta (cluster 1)
✅ Successfully matched: sample2 -> sample2.fasta (cluster 1)
✅ Cluster 1: 15 annotated genomes
✅ Cluster 2: 8 annotated genomes
🎉 SUCCESS: Workflow error fix worked!
```

## Troubleshooting

### If File Matching Fails:
1. **Check file naming**: Ensure FASTA files match taxon names in clusters.csv
2. **Check file extensions**: Pipeline looks for .fasta, .fa, .fas
3. **Check file paths**: Verify files are in the specified input directory

### If Workflow Still Fails:
1. **Test syntax**: `./fix_workflow_error.sh test`
2. **Check logs**: Look for specific error messages in .nextflow.log
3. **Verify input**: Ensure clusters.csv has proper format and column names

## Summary

✅ **Fixed workflow error** - Eliminated "Invalid method invocation `call`" error  
✅ **Simplified channel operations** - Removed problematic `.combine()` operation  
✅ **Enhanced file matching** - Direct file access with better error handling  
✅ **Improved data flow** - Clearer, more maintainable workflow logic  
✅ **Better error recovery** - Graceful handling of missing files and edge cases  

The pipeline should now run successfully without the workflow method invocation error!