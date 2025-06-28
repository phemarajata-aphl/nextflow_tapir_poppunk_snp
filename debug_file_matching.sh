#!/bin/bash

echo "=== File Matching Debug Script ==="
echo "This script helps diagnose why taxon names don't match file names"
echo ""

# Function to display usage
show_usage() {
    echo "Usage: $0 [debug|fix|run] [input_dir] [clusters_csv]"
    echo ""
    echo "Commands:"
    echo "  debug <input> <clusters>  - Debug file matching issues"
    echo "  fix <input> <clusters>    - Create fixed pipeline with better matching"
    echo "  run <input> <output>      - Run pipeline with enhanced file matching"
    echo ""
    echo "Examples:"
    echo "  $0 debug /mnt/disks/ngs-data/subset_100 /path/to/clusters.csv"
    echo "  $0 fix /mnt/disks/ngs-data/subset_100 /path/to/clusters.csv"
    echo "  $0 run /mnt/disks/ngs-data/subset_100 /mnt/disks/ngs-data/results_fixed"
}

# Check arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

COMMAND=$1

case $COMMAND in
    "debug")
        if [ $# -ne 3 ]; then
            echo "Error: Please provide input directory and clusters CSV file"
            echo "Usage: $0 debug <input_dir> <clusters_csv>"
            exit 1
        fi
        
        INPUT_DIR=$2
        CLUSTERS_CSV=$3
        
        echo "Debugging file matching..."
        echo "Input directory: $INPUT_DIR"
        echo "Clusters CSV: $CLUSTERS_CSV"
        echo ""
        
        # Check if files exist
        if [ ! -d "$INPUT_DIR" ]; then
            echo "❌ Error: Input directory does not exist: $INPUT_DIR"
            exit 1
        fi
        
        if [ ! -f "$CLUSTERS_CSV" ]; then
            echo "❌ Error: Clusters CSV file does not exist: $CLUSTERS_CSV"
            exit 1
        fi
        
        # Run debug analysis
        nextflow run debug_file_matching.nf \
            --input "$INPUT_DIR" \
            --clusters "$CLUSTERS_CSV"
        
        echo ""
        echo "Debug analysis complete! Check debug_output/ for results:"
        echo "  - file_matching_debug.txt: Complete analysis"
        echo "  - actual_files.txt: List of actual FASTA files"
        echo "  - cluster_taxons.txt: Taxon names from clusters.csv"
        echo "  - matching_analysis.txt: Detailed matching analysis"
        ;;
        
    "fix")
        if [ $# -ne 3 ]; then
            echo "Error: Please provide input directory and clusters CSV file"
            echo "Usage: $0 fix <input_dir> <clusters_csv>"
            exit 1
        fi
        
        INPUT_DIR=$2
        CLUSTERS_CSV=$3
        
        echo "Creating fixed pipeline with enhanced file matching..."
        echo "This will analyze the naming patterns and create a robust matching solution."
        echo ""
        
        # First run debug to understand the patterns
        $0 debug "$INPUT_DIR" "$CLUSTERS_CSV"
        
        echo ""
        echo "Based on the debug analysis, I'll create an enhanced file matching solution."
        echo "Check the debug output first, then run the enhanced pipeline."
        ;;
        
    "run")
        if [ $# -ne 3 ]; then
            echo "Error: Please provide input and output directories"
            echo "Usage: $0 run <input_dir> <output_dir>"
            exit 1
        fi
        
        INPUT_DIR=$2
        OUTPUT_DIR=$3
        
        echo "Running pipeline with enhanced file matching..."
        echo "Input: $INPUT_DIR"
        echo "Output: $OUTPUT_DIR"
        echo ""
        
        # Run the enhanced pipeline (to be created after debug analysis)
        echo "Enhanced pipeline will be available after debug analysis."
        echo "Please run: $0 debug $INPUT_DIR <clusters_csv> first"
        ;;
        
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_usage
        exit 1
        ;;
esac