#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process TEST_POPPUNK_HELP {
    container 'staphb/poppunk:2.7.5'
    
    output:
    stdout
    
    script:
    """
    echo "=== PopPUNK Version and Help ==="
    poppunk --version || echo "Version command failed"
    echo ""
    echo "=== PopPUNK Main Help ==="
    poppunk --help || echo "Help command failed"
    echo ""
    echo "=== Testing individual commands ==="
    echo "1. Testing poppunk_sketch:"
    poppunk_sketch --help > /dev/null 2>&1 && echo "✅ poppunk_sketch available" || echo "❌ poppunk_sketch not available"
    echo ""
    echo "2. Testing poppunk_assign:"
    poppunk_assign --help > /dev/null 2>&1 && echo "✅ poppunk_assign available" || echo "❌ poppunk_assign not available"
    echo ""
    echo "3. Testing poppunk_qc:"
    poppunk_qc --help > /dev/null 2>&1 && echo "✅ poppunk_qc available" || echo "❌ poppunk_qc not available"
    echo ""
    echo "=== PopPUNK --create-db help ==="
    poppunk --create-db --help || echo "create-db help failed"
    echo ""
    echo "=== PopPUNK --fit-model help ==="
    poppunk --fit-model --help || echo "fit-model help failed"
    """
}

workflow {
    TEST_POPPUNK_HELP() | view
}