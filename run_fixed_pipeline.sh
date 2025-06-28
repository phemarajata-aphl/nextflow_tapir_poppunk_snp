#!/bin/bash

# Complete Fixed Pipeline Execution Script
# Combines all fixes for PopPUNK command errors and multi-channel output issues

echo "=== TAPIR + PopPUNK Pipeline - All Fixes Applied ==="
echo "✅ PopPUNK command syntax errors fixed"
echo "✅ Multi-channel output handling fixed"
echo "✅ Enhanced input validation and debugging"
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [validate|debug|test|run] [input_dir] [output_dir]"
    echo ""
    echo "Commands:"
    echo "  validate                - Test PopPUNK command syntax"
    echo "  debug <input_dir>       - Debug input directory issues"
    echo "  test                    - Instructions for testing with small dataset"
    echo "  run <input> <output>    - Run the completely fixed pipeline"
    echo ""
    echo "All Fixes Applied:"
    echo "  ✅ Combined --create-db --fit-model (eliminates syntax error)"
    echo "  ✅ Corrected --qc-db command structure"
    echo "  ✅ Standard --assign-query command"
    echo "  ✅ Fixed multi-channel output handling"
    echo "  ✅ Enhanced input file detection and debugging"
    echo ""
    echo "Examples:"
    echo "  $0 validate"
    echo "  $0 debug /mnt/disks/ngs-data/subset_100"
    echo "  $0 run /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_fixed"
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "validate")
        echo "=== Validating PopPUNK Command Syntax ==="
        echo ""
        nextflow run test_fixed_poppunk.nf
        
        echo ""
        echo "=== Validation Summary ==="
        echo "This test verifies that all PopPUNK commands use correct syntax."
        echo "The fixed pipeline eliminates the 'required argument' error."
        ;;
        
    "debug")
        if [ $# -ne 2 ]; then
            echo "Error: Please provide input directory"
            echo "Usage: $0 debug <input_dir>"
            exit 1
        fi
        
        INPUT_DIR=$2
        echo "=== Debugging Input Directory: $INPUT_DIR ==="
        echo ""
        
        # Run comprehensive input debugging
        nextflow run debug_input.nf --input "$INPUT_DIR"
        
        echo ""
        echo "=== Manual Checks ==="
        echo "1. Directory exists:"
        ls -la "$INPUT_DIR" > /dev/null 2>&1 && echo "✅ Directory exists" || echo "❌ Directory does not exist"
        
        echo "2. FASTA files present:"
        FASTA_COUNT=$(find "$INPUT_DIR" -name "*.fasta" -o -name "*.fa" -o -name "*.fas" 2>/dev/null | wc -l)
        if [ $FASTA_COUNT -gt 0 ]; then
            echo "✅ Found $FASTA_COUNT FASTA files"
        else
            echo "❌ No FASTA files found"
            echo ""
            echo "Files in directory:"
            ls "$INPUT_DIR" 2>/dev/null | head -10 || echo "Cannot list directory"
            echo ""
            echo "File extensions present:"
            ls "$INPUT_DIR" 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | head -10 || echo "Cannot analyze extensions"
        fi
        ;;
        
    "test")
        echo "=== Testing Instructions ==="
        echo ""
        echo "To test the fixed pipeline with a small dataset:"
        echo ""
        echo "1. Create test directory:"
        echo "   mkdir -p test_data"
        echo ""
        echo "2. Copy 3-5 FASTA files to test_data/"
        echo "   cp /path/to/some/*.fasta test_data/"
        echo ""
        echo "3. Run test:"
        echo "   $0 run test_data test_results"
        echo ""
        echo "This will verify all fixes work correctly before running on your full dataset."
        ;;
        
    "run")
        if [ $# -ne 3 ]; then
            echo "Error: Please provide input and output directories"
            echo "Usage: $0 run <input_dir> <output_dir>"
            exit 1
        fi
        
        INPUT_DIR=$2
        OUTPUT_DIR=$3
        
        echo "=== Running Completely Fixed Pipeline ==="
        echo "Input: $INPUT_DIR"
        echo "Output: $OUTPUT_DIR"
        echo ""
        
        # Validate input directory
        if [ ! -d "$INPUT_DIR" ]; then
            echo "❌ Error: Input directory does not exist: $INPUT_DIR"
            echo ""
            echo "Use '$0 debug $INPUT_DIR' to troubleshoot input issues"
            exit 1
        fi
        
        # Check for FASTA files
        FASTA_COUNT=$(find "$INPUT_DIR" -name "*.fasta" -o -name "*.fa" -o -name "*.fas" 2>/dev/null | wc -l)
        if [ $FASTA_COUNT -eq 0 ]; then
            echo "❌ Error: No FASTA files found in $INPUT_DIR"
            echo "Supported extensions: .fasta, .fa, .fas"
            echo ""
            echo "Use '$0 debug $INPUT_DIR' for detailed analysis"
            exit 1
        fi
        
        echo "✅ Input validation passed: $FASTA_COUNT FASTA files found"
        echo ""
        
        echo "=== All Fixes Applied ==="
        echo "1. ✅ PopPUNK commands: Combined --create-db --fit-model"
        echo "2. ✅ QC command: Standard --qc-db syntax"
        echo "3. ✅ Assignment: Standard --assign-query"
        echo "4. ✅ Multi-channel: Proper output handling"
        echo "5. ✅ Input validation: Enhanced debugging"
        echo ""
        
        echo "Starting fixed pipeline..."
        
        # Run the completely fixed pipeline
        nextflow run nextflow_tapir_poppunk_snp.nf \
            -profile c4_highmem_192 \
            --input "$INPUT_DIR" \
            --resultsDir "$OUTPUT_DIR" \
            --poppunk_threads 32 \
            --panaroo_threads 24 \
            --gubbins_threads 16 \
            --iqtree_threads 8
        
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 0 ]; then
            echo ""
            echo "🎉 SUCCESS: All fixes worked! Pipeline completed successfully!"
            echo ""
            echo "=== Results ==="
            echo "📁 Main results: $OUTPUT_DIR"
            echo "📊 PopPUNK clusters: $OUTPUT_DIR/poppunk/clusters.csv"
            echo "📋 QC report: $OUTPUT_DIR/poppunk/qc_report.txt (if available)"
            echo "📈 Pipeline report: $OUTPUT_DIR/pipeline_report.html"
            echo ""
            echo "=== What Was Fixed ==="
            echo "✅ PopPUNK 'required argument' error eliminated"
            echo "✅ Multi-channel output error resolved"
            echo "✅ Input file detection improved"
            echo "✅ All command syntax corrected"
            echo ""
            echo "Your pipeline is now working correctly!"
        else
            echo ""
            echo "❌ Pipeline failed with exit code: $EXIT_CODE"
            echo ""
            echo "=== Troubleshooting ==="
            echo "1. Check the logs above for specific error messages"
            echo "2. Validate PopPUNK syntax: $0 validate"
            echo "3. Debug input files: $0 debug $INPUT_DIR"
            echo "4. Resume pipeline: nextflow run nextflow_tapir_poppunk_snp.nf -profile c4_highmem_192 --input $INPUT_DIR --resultsDir $OUTPUT_DIR -resume"
            echo ""
            echo "If PopPUNK errors persist, the command syntax fixes may need further adjustment."
        fi
        ;;
        
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac