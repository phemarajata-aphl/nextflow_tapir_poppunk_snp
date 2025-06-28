#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process TEST_POPPUNK_COMMANDS {
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
    
    echo "Testing main operation arguments:"
    echo ""
    
    echo "1. Testing --create-db:"
    poppunk --create-db --help > /dev/null 2>&1 && echo "✅ --create-db valid" || echo "❌ --create-db invalid"
    
    echo "2. Testing --fit-model:"
    poppunk --fit-model --help > /dev/null 2>&1 && echo "✅ --fit-model valid" || echo "❌ --fit-model invalid"
    
    echo "3. Testing --qc-db:"
    poppunk --qc-db --help > /dev/null 2>&1 && echo "✅ --qc-db valid" || echo "❌ --qc-db invalid"
    
    echo "4. Testing --use-model:"
    poppunk --use-model --help > /dev/null 2>&1 && echo "✅ --use-model valid" || echo "❌ --use-model invalid"
    
    echo ""
    echo "Testing problematic combinations:"
    echo ""
    
    echo "5. Testing --assign-query alone (should fail):"
    poppunk --assign-query --help > /dev/null 2>&1 && echo "❌ --assign-query alone works (unexpected)" || echo "✅ --assign-query alone fails (expected)"
    
    echo ""
    echo "=== Fixed Command Structure ==="
    echo "The corrected pipeline now uses:"
    echo "  1. poppunk --create-db (database creation)"
    echo "  2. poppunk --fit-model --ref-db (model fitting)"
    echo "  3. poppunk --qc-db --ref-db (quality control)"
    echo "  4. poppunk --use-model --q-files (cluster assignment)"
    echo ""
    echo "This should eliminate the 'required argument' error."
    """
}

workflow {
    TEST_POPPUNK_COMMANDS() | view
}