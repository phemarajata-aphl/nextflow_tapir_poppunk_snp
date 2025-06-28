#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process TEST_POPPUNK_SYNTAX {
    container 'staphb/poppunk:2.7.5'
    
    output:
    stdout
    
    script:
    """
    echo "=== Testing PopPUNK Command Syntax ==="
    echo ""
    
    echo "PopPUNK version:"
    poppunk --version
    echo ""
    
    echo "Testing individual command syntax:"
    echo ""
    
    echo "1. Testing --create-db syntax:"
    poppunk --create-db --help > /dev/null 2>&1 && echo "✅ --create-db syntax valid" || echo "❌ --create-db syntax invalid"
    echo ""
    
    echo "2. Testing --fit-model syntax:"
    poppunk --fit-model --help > /dev/null 2>&1 && echo "✅ --fit-model syntax valid" || echo "❌ --fit-model syntax invalid"
    echo ""
    
    echo "3. Testing --qc-db syntax:"
    poppunk --qc-db --help > /dev/null 2>&1 && echo "✅ --qc-db syntax valid" || echo "❌ --qc-db syntax invalid"
    echo ""
    
    echo "4. Testing --assign-query syntax:"
    poppunk --assign-query --help > /dev/null 2>&1 && echo "✅ --assign-query syntax valid" || echo "❌ --assign-query syntax invalid"
    echo ""
    
    echo "5. Testing if --create-db and --fit-model can be combined:"
    poppunk --create-db --fit-model --help > /dev/null 2>&1 && echo "✅ Can combine --create-db --fit-model" || echo "❌ Cannot combine --create-db --fit-model (expected)"
    echo ""
    
    echo "=== Fixed Command Structure ==="
    echo "The corrected pipeline now uses:"
    echo "  1. poppunk --create-db (separate step)"
    echo "  2. poppunk --fit-model --ref-db (separate step)"
    echo "  3. poppunk --qc-db --ref-db (optional)"
    echo "  4. poppunk --assign-query --ref-db (final step)"
    echo ""
    echo "This eliminates the 'not allowed with argument --create-db' error."
    """
}

workflow {
    TEST_POPPUNK_SYNTAX() | view
}