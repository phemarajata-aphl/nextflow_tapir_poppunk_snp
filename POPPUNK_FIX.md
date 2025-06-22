# PopPUNK Input Format Fix

## Error Fixed
```
Input reference list is misformatted
Must contain sample name and file, tab separated
```

## Root Cause
PopPUNK requires a tab-separated input file with two columns:
1. Sample name
2. Full path to FASTA file

The original script was only providing file paths without sample names.

## Solution Applied

### Before (Incorrect Format)
```bash
# Only file paths
echo "$(pwd)/$file" >> assembly_list.txt
```

This created a file like:
```
/path/to/sample1.fasta
/path/to/sample2.fasta
```

### After (Correct Format)
```bash
# Tab-separated: sample_name<TAB>file_path
sample_name=$(basename "$file" | sed 's/\.[^.]*$//')
echo -e "$sample_name\t$(pwd)/$file" >> assembly_list.txt
```

This creates a file like:
```
sample1	/path/to/sample1.fasta
sample2	/path/to/sample2.fasta
```

## Key Changes Made

1. **Extract sample names**: Remove file extensions to get clean sample names
2. **Tab-separated format**: Use `echo -e` with `\t` for proper tab separation
3. **Added debugging**: Show first few entries to verify format
4. **Maintained compatibility**: Works with .fasta, .fa, and .fas extensions

## Verification

The fixed script now:
- ✅ Creates properly formatted tab-separated input file
- ✅ Extracts clean sample names from filenames
- ✅ Provides debugging output to verify format
- ✅ Maintains all original functionality

## Testing

You can verify the input format by checking the assembly_list.txt file in the work directory:
```bash
# Check the format
head assembly_list.txt

# Should show:
# sample_name<TAB>full_path_to_file
```

The pipeline should now run successfully through the PopPUNK clustering step.