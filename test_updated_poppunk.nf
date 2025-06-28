#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process TEST_POPPUNK_COMMANDS {
    container 'staphb/poppunk:2.7.5'
    
    output:
    stdout
    
    script:
    """
    echo "=== Testing PopPUNK Command Availability ==="
    echo ""
    
    echo "1. Testing poppunk main command:"
    poppunk --version || echo "poppunk command failed"
    echo ""
    
    echo "2. Testing poppunk_sketch command:"
    poppunk_sketch --help > /dev/null 2>&1 && echo "✅ poppunk_sketch available" || echo "❌ poppunk_sketch not available"
    echo ""
    
    echo "3. Testing poppunk_assign command:"
    poppunk_assign --help > /dev/null 2>&1 && echo "✅ poppunk_assign available" || echo "❌ poppunk_assign not available"
    echo ""
    
    echo "4. Testing poppunk_qc command:"
    poppunk_qc --help > /dev/null 2>&1 && echo "✅ poppunk_qc available" || echo "❌ poppunk_qc not available"
    echo ""
    
    echo "5. Testing legacy commands:"
    poppunk --create-db --help > /dev/null 2>&1 && echo "✅ poppunk --create-db available" || echo "❌ poppunk --create-db not available"
    poppunk --fit-model --help > /dev/null 2>&1 && echo "✅ poppunk --fit-model available" || echo "❌ poppunk --fit-model not available"
    poppunk --assign-query --help > /dev/null 2>&1 && echo "✅ poppunk --assign-query available" || echo "❌ poppunk --assign-query not available"
    echo ""
    
    echo "=== Command Availability Summary ==="
    echo "This test shows which PopPUNK commands are available in the container."
    echo "The updated pipeline will use new commands when available and fall back to legacy commands when needed."
    """
}

workflow {
    TEST_POPPUNK_COMMANDS() | view
}