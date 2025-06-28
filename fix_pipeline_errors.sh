#!/bin/bash

echo "=== Pipeline Error Fix Script ==="
echo "This script helps diagnose and fix the current pipeline errors"
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [debug-input|test-fixed|run-fixed] [input_dir] [output_dir]"
    echo ""
    echo "Commands:"
    echo "  debug-input <dir>       - Debug input directory and file detection"
    echo "  test-fixed             - Test the fixed pipeline with small dataset"
    echo "  run-fixed <input> <output> - Run the fixed pipeline"
    echo ""
    echo "Fixes Applied:"
    echo "  ✅ Multi-channel output error - Fixed POPPUNK output handling"
    echo "  ✅ Enhanced input debugging - Better error messages for file detection"
    echo "  ✅ File pattern matching - Improved FASTA file detection"
    echo ""
    echo "Common Issues:"
    echo "  - Input directory doesn't exist"
    echo "  - FASTA files have different extensions"
    echo "  - File permissions issues"
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "debug-input")
        if [ $# -ne 2 ]; then
            echo "Error: Please provide input directory"
            echo "Usage: $0 debug-input <input_dir>"
            exit 1
        fi
        
        INPUT_DIR=$2
        echo "Debugging input directory: $INPUT_DIR"
        echo ""
        
        # Run debug script
        nextflow run debug_input.nf --input "$INPUT_DIR"
        ;;
        
    "test-fixed")
        echo "Testing the fixed pipeline..."
        echo "This requires a test directory with FASTA files."
        echo ""
        echo "To create test data:"
        echo "  mkdir -p test_data"
        echo "  # Copy some FASTA files to test_data/"
        echo "  $0 run-fixed test_data test_results"
        ;;
        
    "run-fixed")
        if [ $# -ne 3 ]; then
            echo "Error: Please provide input and output directories"
            echo "Usage: $0 run-fixed <input_dir> <output_dir>"
            exit 1
        fi
        
        INPUT_DIR=$2
        OUTPUT_DIR=$3
        
        echo "Running fixed pipeline..."
        echo "Input: $INPUT_DIR"
        echo "Output: $OUTPUT_DIR"
        echo ""
        
        # First debug the input
        echo "=== Debugging Input Directory ==="
        if [ ! -d "$INPUT_DIR" ]; then
            echo "❌ Error: Input directory does not exist: $INPUT_DIR"
            exit 1
        fi
        
        # Check for FASTA files
        FASTA_COUNT=$(find "$INPUT_DIR" -name "*.fasta" -o -name "*.fa" -o -name "*.fas" 2>/dev/null | wc -l)
        if [ $FASTA_COUNT -eq 0 ]; then
            echo "❌ Error: No FASTA files found in $INPUT_DIR"
            echo ""
            echo "Checking what files are present:"
            ls -la "$INPUT_DIR" | head -10
            echo ""
            echo "File extensions found:"
            ls "$INPUT_DIR" | sed 's/.*\.//' | sort | uniq -c | head -10
            echo ""
            echo "Please ensure FASTA files have extensions: .fasta, .fa, or .fas"
            exit 1
        fi
        
        echo "✅ Found $FASTA_COUNT FASTA files"
        echo ""
        
        # Run the fixed pipeline
        echo "=== Running Fixed Pipeline ==="
        nextflow run nextflow_tapir_poppunk_snp.nf \
            -profile c4_highmem_192 \
            --input "$INPUT_DIR" \
            --resultsDir "$OUTPUT_DIR" \
            --poppunk_threads 32 \
            --panaroo_threads 24 \
            --gubbins_threads 16 \
            --iqtree_threads 8
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ Fixed pipeline completed successfully!"
            echo "Results: $OUTPUT_DIR"
        else
            echo ""
            echo "❌ Pipeline still failed. Check logs for details."
            echo "Try resuming with: nextflow run nextflow_tapir_poppunk_snp.nf -profile c4_highmem_192 --input $INPUT_DIR --resultsDir $OUTPUT_DIR -resume"
        fi
        ;;
        
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac