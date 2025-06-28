#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.input = '/mnt/disks/ngs-data/subset_100'

process DEBUG_INPUT {
    output:
    stdout
    
    script:
    """
    echo "=== Debugging Input Directory ==="
    echo "Input directory: ${params.input}"
    echo ""
    
    echo "Checking if directory exists:"
    ls -la "${params.input}" || echo "Directory does not exist"
    echo ""
    
    echo "Looking for FASTA files:"
    find "${params.input}" -name "*.fasta" -o -name "*.fa" -o -name "*.fas" | head -5 || echo "No FASTA files found"
    echo ""
    
    echo "Directory contents (first 10 files):"
    ls "${params.input}" | head -10 || echo "Cannot list directory"
    echo ""
    
    echo "File extensions present:"
    ls "${params.input}" | sed 's/.*\\.//' | sort | uniq -c | head -10 || echo "Cannot analyze extensions"
    """
}

workflow {
    DEBUG_INPUT() | view
}