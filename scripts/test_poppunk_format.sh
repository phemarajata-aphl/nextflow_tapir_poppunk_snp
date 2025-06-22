#!/bin/bash

# Test script to verify PopPUNK input format fix
echo "Testing PopPUNK input format generation..."

# Create test directory with sample files
mkdir -p test_assemblies
cd test_assemblies

# Create some dummy FASTA files
echo ">seq1" > sample1.fasta
echo "ATCGATCGATCG" >> sample1.fasta
echo ">seq2" > sample2.fa
echo "GCTAGCTAGCTA" >> sample2.fa
echo ">seq3" > sample3.fas
echo "TTAATTAATTAA" >> sample3.fas

# Test the format generation logic
echo "Creating assembly list using the fixed format..."
for file in *.{fasta,fa,fas}; do
    if [ -f "$file" ]; then
        # Extract sample name (remove extension)
        sample_name=$(basename "$file" | sed 's/\.[^.]*$//')
        echo -e "$sample_name\t$(pwd)/$file" >> assembly_list.txt
    fi
done

echo "Generated assembly_list.txt:"
cat assembly_list.txt

echo ""
echo "Format verification:"
echo "- Should have 3 lines"
echo "- Each line should have sample_name<TAB>full_path"
echo "- Sample names should be: sample1, sample2, sample3"

# Verify format
line_count=$(wc -l < assembly_list.txt)
echo "Line count: $line_count"

if [ "$line_count" -eq 3 ]; then
    echo "✅ Correct number of lines"
else
    echo "❌ Wrong number of lines"
fi

# Check if tab-separated
if grep -q $'\t' assembly_list.txt; then
    echo "✅ Tab-separated format detected"
else
    echo "❌ No tabs found - format may be incorrect"
fi

# Cleanup
cd ..
rm -rf test_assemblies

echo "Test completed!"