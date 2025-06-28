#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process TEST_DOCKER {
    container 'staphb/poppunk:2.7.5'
    
    output:
    stdout
    
    script:
    """
    echo "Docker container is working!"
    poppunk --version
    """
}

workflow {
    TEST_DOCKER() | view
}