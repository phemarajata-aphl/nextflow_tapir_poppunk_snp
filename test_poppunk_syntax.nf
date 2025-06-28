#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process TEST_POPPUNK_SYNTAX {
    container 'staphb/poppunk:2.7.5'
    
    output:
    stdout
    
    script:
    """
    echo "Testing PopPUNK syntax and version..."
    poppunk --version
    echo ""
    echo "PopPUNK help for create-db:"
    poppunk --create-db --help | head -20
    echo ""
    echo "PopPUNK help for fit-model:"
    poppunk --fit-model --help | head -10
    """
}

workflow {
    TEST_POPPUNK_SYNTAX() | view
}