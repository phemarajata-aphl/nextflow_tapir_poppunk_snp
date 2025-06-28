#!/bin/bash

echo "=== PopPUNK Syntax Fix Script ==="
echo "Fixes the '--fit-model: not allowed with argument --create-db' error"
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [test-syntax|run-fixed|resume] [input_dir] [output_dir]"
    echo ""
    echo "Commands:"
    echo "  test-syntax             - Test the fixed PopPUNK command syntax"
    echo "  run-fixed <input> <output> - Run the pipeline with fixed PopPUNK commands"
    echo "  resume <input> <output>     - Resume the pipeline from where it failed"
    echo ""
    echo "Fix Applied:"
    echo "  ❌ Before: poppunk --create-db --fit-model (not allowed)"
    echo "  ✅ After:  poppunk --create-db (step 1)"
    echo "           poppunk --fit-model --ref-db (step 2)"
    echo ""
    echo "Examples:"
    echo "  $0 test-syntax"
    echo "  $0 run-fixed /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_fixed"
    echo "  $0 resume /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_322_genomes_poppunk"
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "test-syntax")
        echo "Testing fixed PopPUNK command syntax..."
        echo ""
        nextflow run test_poppunk_syntax.nf
        
        echo ""
        echo "This test verifies that the fixed commands work correctly."
        echo "The pipeline now uses separate steps for database creation and model fitting."
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
        echo "=== Fixed PopPUNK Command Structure ==="
        echo "1. Database creation (--create-db)"
        echo "2. Model fitting (--fit-model --ref-db)"
        echo "3. Quality control (--qc-db --ref-db)"
        echo "4. Cluster assignment (--assign-query --ref-db)"
        echo ""
        echo "Starting pipeline with fixed PopPUNK syntax..."
        
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
            echo "🎉 SUCCESS: PopPUNK syntax fix worked! Pipeline completed successfully!"
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
        
        echo "Resuming pipeline with fixed PopPUNK syntax..."
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