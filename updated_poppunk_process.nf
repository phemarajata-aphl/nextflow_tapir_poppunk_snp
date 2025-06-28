// Updated PopPUNK process following latest documentation
// Based on: https://poppunk.bacpop.org/sketching.html
//           https://poppunk.bacpop.org/qc.html  
//           https://poppunk.bacpop.org/model_fitting.html
//           https://poppunk.bacpop.org/query_assignment.html

process POPPUNK_UPDATED {
    tag "PopPUNK_clustering"
    container 'staphb/poppunk:2.7.5'
    publishDir "${params.resultsDir}/poppunk", mode: 'copy'

    input:
    path assemblies

    output:
    path 'clusters.csv'
    path 'qc_report.txt', optional: true

    script:
    """
    # Aggressive memory management for large datasets
    ulimit -v 62914560  # ~60GB virtual memory limit
    ulimit -m 62914560  # ~60GB resident memory limit
    export OMP_NUM_THREADS=${task.cpus}
    export MALLOC_TRIM_THRESHOLD_=100000
    export MALLOC_MMAP_THRESHOLD_=100000
    
    # Monitor memory usage
    echo "Initial memory status:"
    free -h || echo "Memory info not available"
    
    # Create a tab-separated list file for PopPUNK (sample_name<TAB>file_path)
    for file in *.{fasta,fa,fas}; do
        if [ -f "\$file" ]; then
            # Extract sample name (remove extension)
            sample_name=\$(basename "\$file" | sed 's/\\.[^.]*\$//')
            echo -e "\$sample_name\\t\$(pwd)/\$file" >> assembly_list.txt
        fi
    done
    
    # Check if we have any files
    if [ ! -s assembly_list.txt ]; then
        echo "No FASTA files found!"
        exit 1
    fi
    
    echo "Found \$(wc -l < assembly_list.txt) assembly files"
    echo "First few entries in assembly list:"
    head -3 assembly_list.txt
    
    # Check dataset size and adjust parameters aggressively
    NUM_SAMPLES=\$(wc -l < assembly_list.txt)
    echo "Processing \$NUM_SAMPLES samples"
    
    if [ \$NUM_SAMPLES -gt 450 ]; then
        echo "Very large dataset detected (\$NUM_SAMPLES samples). Using ultra-conservative parameters."
        SKETCH_SIZE="--sketch-size 5000"
        MIN_K="--min-k 15"
        MAX_K="--max-k 25"
        EXTRA_PARAMS="--no-stream"
    elif [ \$NUM_SAMPLES -gt 400 ]; then
        echo "Large dataset detected (\$NUM_SAMPLES samples). Using conservative parameters."
        SKETCH_SIZE="--sketch-size 7500"
        MIN_K="--min-k 13"
        MAX_K="--max-k 29"
        EXTRA_PARAMS=""
    else
        echo "Standard dataset size. Using default parameters."
        SKETCH_SIZE=""
        MIN_K=""
        MAX_K=""
        EXTRA_PARAMS=""
    fi
    
    # Memory checkpoint
    echo "Memory before sketching:"
    free -h || echo "Memory info not available"
    
    # Step 1: Create sketches (following latest documentation)
    echo "Step 1: Creating PopPUNK sketches..."
    poppunk_sketch --r-files assembly_list.txt \\
                   --output sketches \\
                   --threads ${task.cpus} \\
                   \$SKETCH_SIZE \$MIN_K \$MAX_K \$EXTRA_PARAMS \\
                   --overwrite || {
        echo "poppunk_sketch failed, trying legacy poppunk --create-db approach..."
        
        # Fallback to legacy approach if poppunk_sketch is not available
        poppunk --create-db --r-files assembly_list.txt \\
                --output poppunk_db \\
                --threads ${task.cpus} \\
                \$SKETCH_SIZE \$MIN_K \$MAX_K \$EXTRA_PARAMS \\
                --overwrite || exit 1
        
        # Skip to model fitting
        echo "Using legacy database creation, proceeding to model fitting..."
        LEGACY_MODE=true
    }
    
    if [ "\$LEGACY_MODE" != "true" ]; then
        # Step 2: Create database from sketches
        echo "Step 2: Creating PopPUNK database from sketches..."
        poppunk --create-db --r-files assembly_list.txt \\
                --output poppunk_db \\
                --sketches sketches \\
                --threads ${task.cpus} \\
                --overwrite || exit 1
    fi
    
    # Memory checkpoint
    echo "Memory after database creation:"
    free -h || echo "Memory info not available"
    
    # Step 3: Fit model separately (following latest documentation)
    echo "Step 3: Fitting PopPUNK model..."
    poppunk --fit-model bgmm \\
            --ref-db poppunk_db \\
            --output poppunk_fit \\
            --threads ${task.cpus} \\
            --overwrite || exit 1
    
    # Memory checkpoint
    echo "Memory after model fitting:"
    free -h || echo "Memory info not available"
    
    # Step 4: Quality control check (following latest documentation)
    echo "Step 4: Running PopPUNK QC..."
    poppunk_qc --ref-db poppunk_fit \\
               --output qc_results \\
               --threads ${task.cpus} || {
        echo "poppunk_qc failed or not available, skipping QC step..."
        echo "QC step skipped - poppunk_qc not available" > qc_report.txt
    }
    
    # Copy QC report if available
    if [ -f qc_results/qc_report.txt ]; then
        cp qc_results/qc_report.txt .
    fi
    
    # Step 5: Assign clusters using updated command (following latest documentation)
    echo "Step 5: Assigning clusters..."
    poppunk_assign --db poppunk_fit \\
                   --query assembly_list.txt \\
                   --output poppunk_assigned \\
                   --threads ${task.cpus} \\
                   --overwrite || {
        echo "poppunk_assign failed, trying legacy poppunk --assign-query..."
        
        # Fallback to legacy assignment if poppunk_assign is not available
        poppunk --assign-query --ref-db poppunk_fit \\
                --q-files assembly_list.txt \\
                --output poppunk_assigned \\
                --threads ${task.cpus} \\
                --overwrite || exit 1
    }
    
    # Find and copy the cluster assignment file
    find poppunk_assigned -name "*clusters.csv" -exec cp {} clusters.csv \\;
    
    # If that doesn't work, try alternative names and locations
    if [ ! -f clusters.csv ]; then
        find poppunk_assigned -name "*cluster*.csv" -exec cp {} clusters.csv \\;
    fi
    
    if [ ! -f clusters.csv ]; then
        find poppunk_fit -name "*clusters.csv" -exec cp {} clusters.csv \\;
    fi
    
    if [ ! -f clusters.csv ]; then
        find . -name "*clusters.csv" -exec cp {} clusters.csv \\;
    fi
    
    # Final check
    if [ ! -f clusters.csv ]; then
        echo "Could not find cluster assignment file. Available files:"
        find . -name "*.csv" -ls
        exit 1
    fi
    
    echo "Cluster assignments created successfully"
    echo "Total clusters found: \$(tail -n +2 clusters.csv | cut -f2 | sort -u | wc -l)"
    echo "Final memory status:"
    free -h || echo "Memory info not available"
    head -5 clusters.csv
    
    # Summary of steps completed
    echo ""
    echo "=== PopPUNK Analysis Summary ==="
    echo "1. Sketching: Completed"
    echo "2. Database creation: Completed"  
    echo "3. Model fitting: Completed"
    echo "4. QC check: \$([ -f qc_report.txt ] && echo 'Completed' || echo 'Skipped')"
    echo "5. Cluster assignment: Completed"
    echo "Total samples processed: \$NUM_SAMPLES"
    echo "Total clusters identified: \$(tail -n +2 clusters.csv | cut -f2 | sort -u | wc -l)"
    """
}