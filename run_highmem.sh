#!/bin/bash

# Script to run TAPIR + PopPUNK pipeline on c4-highmem-192 instance
# Optimized for 192 vCPUs and 1,488 GB Memory on Debian

echo "=== TAPIR + PopPUNK Pipeline - High-Memory VM Setup ==="
echo "VM Specs: c4-highmem-192 (192 vCPUs, 1,488 GB Memory)"
echo "OS: Debian"
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [test|run] [input_dir] [output_dir]"
    echo ""
    echo "Commands:"
    echo "  test                    - Test the high-memory profile configuration"
    echo "  run <input> <output>    - Run the full pipeline"
    echo ""
    echo "Examples:"
    echo "  $0 test"
    echo "  $0 run /path/to/assemblies /path/to/results"
    echo ""
    echo "Profile Features:"
    echo "  - PopPUNK: 32 threads, 400 GB memory"
    echo "  - Panaroo: 24 threads, 100 GB memory per cluster"
    echo "  - Gubbins: 16 threads, 80 GB memory per cluster"
    echo "  - IQ-TREE: 8 threads, 40 GB memory per cluster"
    echo "  - Queue size: 20 concurrent processes"
    echo "  - Total executor: 192 CPUs, 1400 GB memory"
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "test")
        echo "Testing high-memory profile configuration..."
        echo ""
        nextflow run test_highmem_profile.nf -profile c4_highmem_192
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "✓ High-memory profile test successful!"
            echo "You can now run the full pipeline with:"
            echo "$0 run /path/to/your/assemblies /path/to/your/results"
        else
            echo ""
            echo "✗ Profile test failed. Please check Docker installation and permissions."
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
            echo "Error: Input directory does not exist: $INPUT_DIR"
            exit 1
        fi
        
        # Check for FASTA files
        FASTA_COUNT=$(find "$INPUT_DIR" -name "*.fasta" -o -name "*.fa" -o -name "*.fas" | wc -l)
        if [ $FASTA_COUNT -eq 0 ]; then
            echo "Error: No FASTA files found in $INPUT_DIR"
            echo "Supported extensions: .fasta, .fa, .fas"
            exit 1
        fi
        
        echo "Found $FASTA_COUNT FASTA files in $INPUT_DIR"
        echo "Output will be saved to: $OUTPUT_DIR"
        echo ""
        echo "Starting pipeline with high-memory profile..."
        echo "This will use:"
        echo "  - PopPUNK: 32 threads, 400 GB memory"
        echo "  - Up to 20 concurrent processes"
        echo "  - Total system: 192 CPUs, 1400 GB memory"
        echo ""
        
        # Run the pipeline
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
            echo "✓ Pipeline completed successfully!"
            echo "Results are available in: $OUTPUT_DIR"
        else
            echo ""
            echo "✗ Pipeline failed. Check the logs for details."
            echo "You can resume with: nextflow run nextflow_tapir_poppunk_snp.nf -profile c4_highmem_192 --input $INPUT_DIR --resultsDir $OUTPUT_DIR -resume"
        fi
        ;;
        
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac