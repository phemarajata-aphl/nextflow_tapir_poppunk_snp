#!/bin/bash

echo "=== PopPUNK Argument Fix Script ==="
echo "Fixes the '--q-files: unrecognized arguments' error"
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [test-args|run-fixed|resume] [input_dir] [output_dir]"
    echo ""
    echo "Commands:"
    echo "  test-args               - Test PopPUNK argument syntax"
    echo "  run-fixed <input> <output> - Run pipeline with fixed arguments"
    echo "  resume <input> <output>     - Resume pipeline from failure"
    echo ""
    echo "Fix Applied:"
    echo "  ❌ Before: poppunk --use-model --q-files (invalid argument)"
    echo "  ✅ After:  Simplified assignment with proper fallbacks"
    echo ""
    echo "Examples:"
    echo "  $0 test-args"
    echo "  $0 run-fixed /path/to/input /path/to/output"
    echo "  $0 resume /path/to/input /path/to/output"
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "test-args")
        echo "Testing PopPUNK argument syntax..."
        echo ""
        nextflow run test_poppunk_args.nf
        
        echo ""
        echo "This test shows the correct argument syntax for PopPUNK commands."
        echo "The fixed pipeline eliminates the '--q-files' error."
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
            exit 1
        fi
        
        echo "✅ Found $FASTA_COUNT FASTA files in $INPUT_DIR"
        echo "Output will be saved to: $OUTPUT_DIR"
        echo ""
        echo "=== PopPUNK Argument Fix Applied ==="
        echo "1. Removed invalid --q-files argument"
        echo "2. Added proper fallback mechanisms"
        echo "3. Simplified cluster assignment logic"
        echo "4. Enhanced error handling"
        echo ""
        echo "Starting pipeline with fixed arguments..."
        
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
            echo "🎉 SUCCESS: PopPUNK argument fix worked! Pipeline completed successfully!"
            echo ""
            echo "Results:"
            echo "  📁 Main results: $OUTPUT_DIR"
            echo "  📊 PopPUNK clusters: $OUTPUT_DIR/poppunk/clusters.csv"
            echo "  📋 QC report: $OUTPUT_DIR/poppunk/qc_report.txt (if available)"
        else
            echo ""
            echo "❌ Pipeline failed. Check logs for details."
            echo "To resume: $0 resume $INPUT_DIR $OUTPUT_DIR"
        fi
        ;;
        
    "resume")
        if [ $# -ne 3 ]; then
            echo "Error: Please provide input and output directories"
            echo "Usage: $0 resume <input_dir> <output_dir>"
            exit 1
        fi
        
        INPUT_DIR=$2
        OUTPUT_DIR=$3
        
        echo "Resuming pipeline with fixed PopPUNK arguments..."
        echo "Input: $INPUT_DIR"
        echo "Output: $OUTPUT_DIR"
        echo ""
        
        # Resume the pipeline
        nextflow run nextflow_tapir_poppunk_snp.nf \
            -profile c4_highmem_192 \
            --input "$INPUT_DIR" \
            --resultsDir "$OUTPUT_DIR" \
            --poppunk_threads 32 \
            --panaroo_threads 24 \
            --gubbins_threads 16 \
            --iqtree_threads 8 \
            -resume
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "🎉 SUCCESS: Pipeline resumed and completed successfully!"
        else
            echo ""
            echo "❌ Pipeline still failed. Check logs for additional issues."
        fi
        ;;
        
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac