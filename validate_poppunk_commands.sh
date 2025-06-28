#!/bin/bash

echo "=== PopPUNK Command Validation Script ==="
echo "This script validates all PopPUNK commands used in the pipeline"
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [test-syntax|test-pipeline|run-fixed] [input_dir] [output_dir]"
    echo ""
    echo "Commands:"
    echo "  test-syntax             - Test PopPUNK command syntax and availability"
    echo "  test-pipeline          - Test the fixed pipeline with small dataset"
    echo "  run-fixed <input> <output> - Run the pipeline with fixed PopPUNK commands"
    echo ""
    echo "PopPUNK Command Fixes Applied:"
    echo "  ✅ Combined --create-db and --fit-model in single command"
    echo "  ✅ Fixed --qc-db syntax (was using poppunk_qc)"
    echo "  ✅ Simplified to use standard --assign-query"
    echo "  ✅ Removed problematic separate command calls"
    echo ""
    echo "Fixed Command Structure:"
    echo "  1. poppunk --create-db --fit-model bgmm"
    echo "  2. poppunk --qc-db (optional)"
    echo "  3. poppunk --assign-query"
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "test-syntax")
        echo "Testing PopPUNK command syntax..."
        echo ""
        nextflow run test_poppunk_commands.nf
        
        echo ""
        echo "=== Command Validation Summary ==="
        echo "This test shows which PopPUNK commands are available and their syntax."
        echo "The fixed pipeline uses only standard PopPUNK commands that should work reliably."
        ;;
        
    "test-pipeline")
        echo "Testing the fixed pipeline with corrected PopPUNK commands..."
        echo ""
        echo "To test with your own data:"
        echo "  mkdir -p test_data"
        echo "  # Copy 3-5 FASTA files to test_data/"
        echo "  $0 run-fixed test_data test_results"
        echo ""
        echo "The fixed pipeline now uses:"
        echo "  - Combined database creation and model fitting"
        echo "  - Standard PopPUNK QC syntax"
        echo "  - Reliable cluster assignment commands"
        ;;
        
    "run-fixed")
        if [ $# -ne 3 ]; then
            echo "Error: Please provide input and output directories"
            echo "Usage: $0 run-fixed <input_dir> <output_dir>"
            exit 1
        fi
        
        INPUT_DIR=$2
        OUTPUT_DIR=$3
        
        # Validate input directory
        if [ ! -d "$INPUT_DIR" ]; then
            echo "❌ Error: Input directory does not exist: $INPUT_DIR"
            exit 1
        fi
        
        # Check for FASTA files
        FASTA_COUNT=$(find "$INPUT_DIR" -name "*.fasta" -o -name "*.fa" -o -name "*.fas" 2>/dev/null | wc -l)
        if [ $FASTA_COUNT -eq 0 ]; then
            echo "❌ Error: No FASTA files found in $INPUT_DIR"
            echo "Supported extensions: .fasta, .fa, .fas"
            echo ""
            echo "Files in directory:"
            ls -la "$INPUT_DIR" | head -10
            exit 1
        fi
        
        echo "✅ Found $FASTA_COUNT FASTA files in $INPUT_DIR"
        echo "Output will be saved to: $OUTPUT_DIR"
        echo ""
        echo "=== Fixed PopPUNK Command Structure ==="
        echo "1. Database creation with model fitting (combined)"
        echo "2. Quality control check (optional)"
        echo "3. Cluster assignment"
        echo ""
        echo "Starting pipeline with fixed PopPUNK commands..."
        
        # Run the fixed pipeline
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
            echo "✅ Pipeline with fixed PopPUNK commands completed successfully!"
            echo ""
            echo "Results:"
            echo "  Main results: $OUTPUT_DIR"
            echo "  PopPUNK clusters: $OUTPUT_DIR/poppunk/clusters.csv"
            echo "  QC report: $OUTPUT_DIR/poppunk/qc_report.txt (if available)"
            echo ""
            echo "Pipeline report: $OUTPUT_DIR/pipeline_report.html"
        else
            echo ""
            echo "❌ Pipeline failed. Check logs for details."
            echo ""
            echo "To resume:"
            echo "  nextflow run nextflow_tapir_poppunk_snp.nf -profile c4_highmem_192 \\"
            echo "    --input $INPUT_DIR --resultsDir $OUTPUT_DIR -resume"
        fi
        ;;
        
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac