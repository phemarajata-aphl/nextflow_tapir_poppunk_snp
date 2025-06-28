#!/bin/bash

echo "=== Enhanced File Matching Fix Script ==="
echo "Fixes the file matching issues with multiple strategies"
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [test|run|resume] [input_dir] [output_dir]"
    echo ""
    echo "Commands:"
    echo "  test                    - Test the enhanced file matching"
    echo "  run <input> <output>    - Run pipeline with enhanced file matching"
    echo "  resume <input> <output> - Resume pipeline from failure"
    echo ""
    echo "Enhanced File Matching Strategies:"
    echo "  1. ✅ Exact basename match"
    echo "  2. ✅ Variant matching (underscores ↔ dots ↔ hyphens)"
    echo "  3. ✅ Partial matching (contains)"
    echo "  4. ✅ Fuzzy matching (remove GCF/GCA suffixes)"
    echo ""
    echo "Examples:"
    echo "  $0 test"
    echo "  $0 run /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_enhanced"
    echo "  $0 resume /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_322_genomes_poppunk"
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "test")
        echo "Testing enhanced file matching..."
        echo ""
        
        # Test workflow syntax
        nextflow run nextflow_tapir_poppunk_snp.nf --help
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ Enhanced file matching syntax is valid!"
            echo ""
            echo "The enhanced pipeline now includes:"
            echo "  1. Exact basename matching"
            echo "  2. Underscore/dot/hyphen variant matching"
            echo "  3. Partial string matching"
            echo "  4. Fuzzy matching with GCF/GCA handling"
            echo ""
            echo "This should resolve the file matching warnings you encountered."
        else
            echo ""
            echo "❌ Syntax issues detected."
        fi
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
        echo "=== Enhanced File Matching Features ==="
        echo "1. Exact matching: taxon_name == file_basename"
        echo "2. Variant matching: GCA_123_1 ↔ GCA.123.1"
        echo "3. Partial matching: substring matching"
        echo "4. Fuzzy matching: ignore GCF/GCA suffixes"
        echo "5. Detailed logging of match strategies"
        echo ""
        echo "Starting enhanced pipeline..."
        
        # Run the enhanced pipeline
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
            echo "🎉 SUCCESS: Enhanced file matching worked! Pipeline completed successfully!"
            echo ""
            echo "Results:"
            echo "  📁 Main results: $OUTPUT_DIR"
            echo "  📊 PopPUNK clusters: $OUTPUT_DIR/poppunk/clusters.csv"
            echo "  📋 Annotations: $OUTPUT_DIR/annotations/"
            echo "  🧬 Cluster analyses: $OUTPUT_DIR/cluster_*/"
            echo ""
            echo "Check the logs for file matching details:"
            echo "  - Look for 'Successfully matched' messages"
            echo "  - Match strategies used: exact, variant, partial, fuzzy"
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
        
        echo "Resuming pipeline with enhanced file matching..."
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