#!/bin/bash

echo "=== PopPUNK Final Fix Script ==="
echo "Fixes both QC and assignment issues based on latest documentation"
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [test-commands|run-fixed|resume] [input_dir] [output_dir]"
    echo ""
    echo "Commands:"
    echo "  test-commands           - Test PopPUNK command availability"
    echo "  run-fixed <input> <output> - Run pipeline with all fixes"
    echo "  resume <input> <output>     - Resume pipeline from failure"
    echo ""
    echo "Fixes Applied:"
    echo "  ✅ Step 3 QC: Fixed reference database (poppunk_db instead of poppunk_fit)"
    echo "  ✅ Step 4 Assignment: Uses poppunk_assign (with fallback to --use-model)"
    echo "  ✅ Following latest PopPUNK documentation"
    echo ""
    echo "Based on: https://poppunk.bacpop.org/query_assignment.html"
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "test-commands")
        echo "Testing PopPUNK command availability and syntax..."
        echo ""
        nextflow run test_poppunk_assign.nf
        
        echo ""
        echo "This test verifies the availability of:"
        echo "  - poppunk_assign (preferred for Step 4)"
        echo "  - poppunk --use-model (fallback for Step 4)"
        echo "  - poppunk --qc-db (for Step 3)"
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
        echo "=== Final PopPUNK Fixes Applied ==="
        echo "1. Database creation: poppunk --create-db"
        echo "2. Model fitting: poppunk --fit-model --ref-db"
        echo "3. QC check: poppunk --qc-db --ref-db poppunk_db (fixed reference)"
        echo "4. Assignment: poppunk_assign --db (with fallback)"
        echo ""
        echo "Starting pipeline with all fixes..."
        
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
            echo "🎉 SUCCESS: All PopPUNK fixes worked! Pipeline completed successfully!"
            echo ""
            echo "Results:"
            echo "  📁 Main results: $OUTPUT_DIR"
            echo "  📊 PopPUNK clusters: $OUTPUT_DIR/poppunk/clusters.csv"
            echo "  📋 QC report: $OUTPUT_DIR/poppunk/qc_report.txt (if available)"
            echo ""
            echo "=== What Was Fixed ==="
            echo "✅ Step 3 QC: Fixed missing .dists.pkl file issue"
            echo "✅ Step 4 Assignment: Now uses poppunk_assign command"
            echo "✅ Proper fallback mechanisms for compatibility"
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
        
        echo "Resuming pipeline with all PopPUNK fixes..."
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