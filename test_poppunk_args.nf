#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process TEST_POPPUNK_ARGS {
    container 'staphb/poppunk:2.7.5'
    
    output:
    stdout
    
    script:
    """
    echo "=== Testing PopPUNK Argument Syntax ==="
    echo ""
    
    echo "PopPUNK version:"
    poppunk --version
    echo ""
    
    echo "Testing --use-model help:"
    poppunk --use-model --help | grep -A 10 -B 5 "query\|files" || echo "No query/files options found"
    echo ""
    
    echo "Testing poppunk_assign help:"
    poppunk_assign --help > /dev/null 2>&1 && echo "poppunk_assign available" || echo "poppunk_assign not available"
    
    if command -v poppunk_assign > /dev/null 2>&1; then
        echo "poppunk_assign help:"
        poppunk_assign --help | head -20
    fi
    
    echo ""
    echo "Full poppunk help for reference:"
    poppunk --help | grep -A 5 -B 5 "query\|files"
    """
}

workflow {
    TEST_POPPUNK_ARGS() | view
}