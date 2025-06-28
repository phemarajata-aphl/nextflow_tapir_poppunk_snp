#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process CHECK_POPPUNK_VERSION {
    container 'staphb/poppunk:2.7.5'
    
    output:
    stdout
    
    script:
    """
    echo "=== PopPUNK Version and Available Commands ==="
    poppunk --version
    echo ""
    echo "=== PopPUNK Help ==="
    poppunk --help
    echo ""
    echo "=== Available subcommands ==="
    poppunk --help | grep -A 20 "positional arguments"
    """
}

workflow {
    CHECK_POPPUNK_VERSION() | view
}