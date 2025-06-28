#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process TEST_RESOURCES {
    tag "Resource_Test"
    container 'staphb/poppunk:2.7.5'
    
    output:
    stdout
    
    script:
    """
    echo "=== High-Memory VM Resource Test ==="
    echo "Available CPUs: ${task.cpus}"
    echo "Available Memory: ${task.memory}"
    echo "Container: ${task.container}"
    echo ""
    echo "System Information:"
    nproc --all || echo "nproc not available"
    free -h || echo "free not available"
    echo ""
    echo "PopPUNK Version:"
    poppunk --version
    echo ""
    echo "Test completed successfully!"
    """
}

workflow {
    TEST_RESOURCES() | view
}