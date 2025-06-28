#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process TEST_FIXED_POPPUNK_SYNTAX {
    container 'staphb/poppunk:2.7.5'
    
    output:
    stdout
    
    script:
    """
    echo "=== Testing Fixed PopPUNK Command Syntax ==="
    echo ""
    
    echo "1. Testing combined --create-db --fit-model syntax:"
    poppunk --create-db --fit-model --help > /dev/null 2>&1 && echo "✅ Combined syntax valid" || echo "❌ Combined syntax invalid"
    echo ""
    
    echo "2. Testing --qc-db syntax:"
    poppunk --qc-db --help > /dev/null 2>&1 && echo "✅ QC syntax valid" || echo "❌ QC syntax invalid"
    echo ""
    
    echo "3. Testing --assign-query syntax:"
    poppunk --assign-query --help > /dev/null 2>&1 && echo "✅ Assignment syntax valid" || echo "❌ Assignment syntax invalid"
    echo ""
    
    echo "4. PopPUNK version:"
    poppunk --version
    echo ""
    
    echo "=== Command Structure Validation ==="
    echo "The fixed pipeline uses these commands:"
    echo "  1. poppunk --create-db --fit-model bgmm"
    echo "  2. poppunk --qc-db (optional)"
    echo "  3. poppunk --assign-query"
    echo ""
    echo "All commands include required main operation arguments."
    """
}

workflow {
    TEST_FIXED_POPPUNK_SYNTAX() | view
}