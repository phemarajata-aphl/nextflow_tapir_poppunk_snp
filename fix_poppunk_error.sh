#!/bin/bash

echo "=== PopPUNK Error Fix Script ==="
echo "This script helps diagnose and fix the PopPUNK --fit-model error"
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [test-syntax|test-pipeline|run-fixed]"
    echo ""
    echo "Commands:"
    echo "  test-syntax     - Test PopPUNK command syntax and version"
    echo "  test-pipeline   - Test the fixed pipeline with a small dataset"
    echo "  run-fixed       - Run your original command with the fixed pipeline"
    echo ""
    echo "The fix changes PopPUNK workflow from:"
    echo "  OLD: --create-db → --fit-model (separate) → --assign-query"
    echo "  NEW: --create-db --fit-model bgmm (combined) → --assign-query"
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "test-syntax")
        echo "Testing PopPUNK syntax and version..."
        echo ""
        nextflow run test_poppunk_syntax.nf -profile c4_highmem_192
        ;;
        
    "test-pipeline")
        echo "This would test the pipeline with a small dataset."
        echo "Make sure you have some test FASTA files in a test directory first."
        echo ""
        echo "Example:"
        echo "mkdir -p test_data"
        echo "# Copy a few FASTA files to test_data/"
        echo "nextflow run nextflow_tapir_poppunk_snp.nf -profile c4_highmem_192 --input test_data --resultsDir test_results"
        ;;
        
    "run-fixed")
        echo "Running your original command with the fixed PopPUNK process..."
        echo ""
        echo "Original command:"
        echo "nextflow run nextflow_tapir_poppunk_snp.nf -profile c4_highmem_192 --input /mnt/disks/ngs-data/subset_100 --resultsDir /mnt/disks/ngs-data/results_322_genomes_poppunk"
        echo ""
        echo "Running with -resume to continue from where it failed..."
        
        nextflow run nextflow_tapir_poppunk_snp.nf \
            -profile c4_highmem_192 \
            --input /mnt/disks/ngs-data/subset_100 \
            --resultsDir /mnt/disks/ngs-data/results_322_genomes_poppunk \
            -resume
        ;;
        
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac