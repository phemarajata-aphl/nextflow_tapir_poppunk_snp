#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process TEST_POPPUNK_ASSIGN {
    container 'staphb/poppunk:2.7.5'
    
    output:
    stdout
    
    script:
    """
    echo "=== Testing PopPUNK Assignment Commands ==="
    echo ""
    
    echo "PopPUNK version:"
    poppunk --version
    echo ""
    
    echo "Testing command availability:"
    echo ""
    
    echo "1. Testing poppunk_assign command:"
    poppunk_assign --help > /dev/null 2>&1 && echo "✅ poppunk_assign available" || echo "❌ poppunk_assign not available"
    
    echo "2. Testing poppunk --use-model:"
    poppunk --use-model --help > /dev/null 2>&1 && echo "✅ poppunk --use-model available" || echo "❌ poppunk --use-model not available"
    
    echo "3. Testing poppunk --qc-db:"
    poppunk --qc-db --help > /dev/null 2>&1 && echo "✅ poppunk --qc-db available" || echo "❌ poppunk --qc-db not available"
    
    echo ""
    echo "=== Fixed Command Structure ==="
    echo "Based on PopPUNK documentation (https://poppunk.bacpop.org/query_assignment.html):"
    echo "  1. poppunk --create-db (database creation)"
    echo "  2. poppunk --fit-model --ref-db (model fitting)"
    echo "  3. poppunk --qc-db --ref-db (quality control - optional)"
    echo "  4. poppunk_assign --db (cluster assignment - preferred)"
    echo "     OR poppunk --use-model --ref-db (fallback)"
    echo ""
    echo "This should resolve both the QC and assignment issues."
    """
}

workflow {
    TEST_POPPUNK_ASSIGN() | view
}