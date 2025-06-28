#!/bin/bash

# Script to run the updated TAPIR + PopPUNK pipeline with latest PopPUNK commands
# Updated to follow latest PopPUNK documentation

echo "=== Updated TAPIR + PopPUNK Pipeline ==="
echo "Now includes latest PopPUNK commands with fallback support"
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [test-commands|test-pipeline|run] [input_dir] [output_dir]"
    echo ""
    echo "Commands:"
    echo "  test-commands           - Test PopPUNK command availability"
    echo "  test-pipeline          - Test the updated pipeline with small dataset"
    echo "  run <input> <output>   - Run the full updated pipeline"
    echo ""
    echo "Fixed PopPUNK Commands:"
    echo "  ✅ Combined --create-db --fit-model (fixed syntax error)"
    echo "  ✅ Corrected --qc-db command structure"
    echo "  ✅ Standard --assign-query command"
    echo "  ✅ Eliminated problematic separate commands"
    echo "  ✅ Enhanced error handling and logging"
    echo ""
    echo "Examples:"
    echo "  $0 test-commands"
    echo "  $0 run /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_updated"
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "test-commands")
        echo "Testing PopPUNK command availability..."
        echo ""
        nextflow run test_updated_poppunk.nf -profile c4_highmem_192
        
        echo ""
        echo "This test shows which PopPUNK commands are available."
        echo "The pipeline will automatically use the best available commands."
        ;;
        
    "test-pipeline")
        echo "This would test the updated pipeline with a small dataset."
        echo "Make sure you have test FASTA files in a test directory first."
        echo ""
        echo "Example setup:"
        echo "  mkdir -p test_data"
        echo "  # Copy 3-5 FASTA files to test_data/"
        echo "  $0 run test_data test_results"
        ;;
        
    "run")
        if [ $# -ne 3 ]; then
            echo "Error: Please provide input and output directories"
            echo "Usage: $0 run <input_dir> <output_dir>"
            exit 1
        fi
        
        INPUT_DIR=$2
        OUTPUT_DIR=$3
        
        # Validate input directory
        if [ ! -d "$INPUT_DIR" ]; then
            echo "Error: Input directory does not exist: $INPUT_DIR"
            exit 1
        fi
        
        # Check for FASTA files with better debugging
        FASTA_COUNT=$(find "$INPUT_DIR" -name "*.fasta" -o -name "*.fa" -o -name "*.fas" 2>/dev/null | wc -l)
        if [ $FASTA_COUNT -eq 0 ]; then
            echo "Error: No FASTA files found in $INPUT_DIR"
            echo "Supported extensions: .fasta, .fa, .fas"
            echo ""
            echo "Debugging information:"
            echo "Directory contents (first 10 files):"
            ls "$INPUT_DIR" | head -10 || echo "Cannot list directory"
            echo ""
            echo "File extensions present:"
            ls "$INPUT_DIR" | sed 's/.*\.//' | sort | uniq -c | head -10 || echo "Cannot analyze extensions"
            echo ""
            echo "Use './fix_pipeline_errors.sh debug-input $INPUT_DIR' for detailed debugging"
            exit 1
        fi
        
        echo "Found $FASTA_COUNT FASTA files in $INPUT_DIR"
        echo "Output will be saved to: $OUTPUT_DIR"
        echo ""
        echo "=== Fixed PopPUNK Command Structure ==="
        echo "1. Database + Model: Combined --create-db --fit-model"
        echo "2. Quality Control: Standard --qc-db (optional)"
        echo "3. Assignment: Standard --assign-query"
        echo "4. All commands now include required operation arguments"
        echo "5. Eliminated syntax errors and problematic commands"
        echo ""
        echo "Starting pipeline with fixed PopPUNK commands..."
        
        # Run the updated pipeline
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
            echo "=== Results Summary ==="
            echo "Main results: $OUTPUT_DIR"
            echo "PopPUNK clusters: $OUTPUT_DIR/poppunk/clusters.csv"
            echo "QC report: $OUTPUT_DIR/poppunk/qc_report.txt (if available)"
            echo ""
            echo "Check the pipeline report for detailed execution information:"
            echo "  $OUTPUT_DIR/pipeline_report.html"
        else
            echo ""
            echo "❌ Pipeline failed. Check the logs for details."
            echo ""
            echo "To resume from where it failed:"
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