#!/usr/bin/env nextflow

/*
 * TAPIR + PopPUNK + Per-Clade SNP Analysis Pipeline
 * DSL2 pipeline optimized for large datasets with Google Cloud Batch support
 * 
 * Steps:
 *   1. PopPUNK clustering of assembled genomes
 *   2. Split genomes by cluster
 *   3. For each cluster: run Panaroo → Gubbins → IQ-TREE
 *
 * Requirements:
 *   - Nextflow (v23+)
 *   - Docker/Singularity containers
 *   - StaPH-B Docker images:
 *       staphb/poppunk:2.7.5 (PopPUNK clustering - latest)
 *       staphb/panaroo:1.5.2 (Pan-genome analysis - latest)
 *       staphb/gubbins:3.3.5 (Recombination removal - latest)
 *       staphb/iqtree2:2.4.0 (Phylogenetic tree building - latest)
 */

nextflow.enable.dsl=2

// Help message
if (params.help) {
    log.info """
    TAPIR + PopPUNK + Per-Clade SNP Analysis Pipeline
    
    Usage:
        nextflow run nextflow_tapir_poppunk_snp.nf --input <path_to_assemblies> --resultsDir <output_directory>
    
    Required arguments:
        --input         Path to directory containing FASTA assemblies
                        Local: ./assemblies
                        Cloud: gs://bucket-name/path/to/assemblies
        --resultsDir    Path to output directory
                        Local: ./results
                        Cloud: gs://bucket-name/path/to/results
    
    Optional arguments:
        --poppunk_threads   Number of threads for PopPUNK (default: 8 local, 16 cloud)
        --panaroo_threads   Number of threads for Panaroo (default: 16 local, 8 cloud)
        --gubbins_threads   Number of threads for Gubbins (default: 8 local, 4 cloud)
        --iqtree_threads    Number of threads for IQ-TREE (default: 4)
        --large_dataset_threshold      Threshold for conservative PopPUNK parameters (default: 400)
        --very_large_dataset_threshold Threshold for ultra-conservative PopPUNK parameters (default: 450)
    
    Execution profiles:
        -profile ubuntu_docker    Local execution with Docker (Ubuntu optimized)
        -profile c4_highmem_192   High-memory VM (192 vCPUs, 1,488 GB) on Debian
        -profile google_batch     Google Cloud Batch execution
        -profile standard         Default local execution
    
    Examples:
        # Local execution
        nextflow run nextflow_tapir_poppunk_snp.nf -profile ubuntu_docker --input ./assemblies --resultsDir ./results
        
        # High-memory VM execution (c4-highmem-192)
        nextflow run nextflow_tapir_poppunk_snp.nf -profile c4_highmem_192 --input ./assemblies --resultsDir ./results
        
        # Google Cloud execution
        nextflow run nextflow_tapir_poppunk_snp.nf -profile google_batch \\
            --input gs://bucket/assemblies --resultsDir gs://bucket/results
    """
    exit 0
}

// Process definitions
process POPPUNK {
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
    
    # Step 1: Create database only (separate from model fitting)
    echo "Step 1: Creating PopPUNK database..."
    poppunk --create-db --r-files assembly_list.txt \\
            --output poppunk_db \\
            --threads ${task.cpus} \\
            \$SKETCH_SIZE \$MIN_K \$MAX_K \$EXTRA_PARAMS \\
            --overwrite || exit 1
    
    # Memory checkpoint
    echo "Memory after database creation:"
    free -h || echo "Memory info not available"
    
    # Step 2: Fit model separately (required separate step)
    echo "Step 2: Fitting PopPUNK model..."
    poppunk --fit-model bgmm \\
            --ref-db poppunk_db \\
            --output poppunk_fit \\
            --threads ${task.cpus} \\
            --overwrite || exit 1
    
    # Memory checkpoint
    echo "Memory after model fitting:"
    free -h || echo "Memory info not available"
    
    # Step 3: Quality control check (optional - skip if problematic)
    echo "Step 3: Running PopPUNK QC (optional)..."
    poppunk --qc-db --ref-db poppunk_db \\
            --output qc_results \\
            --threads ${task.cpus} \\
            --overwrite || {
        echo "PopPUNK QC failed or not available, skipping QC step..."
        echo "QC step skipped - PopPUNK QC not available or failed" > qc_report.txt
    }
    
    # Copy QC report if available
    if [ -f qc_results/qc_report.txt ]; then
        cp qc_results/qc_report.txt .
    elif [ -f qc_results/qc_summary.txt ]; then
        cp qc_results/qc_summary.txt qc_report.txt
    fi
    
    # Step 4: Assign clusters - simplified approach
    echo "Step 4: Assigning clusters..."
    
    # Try poppunk_assign first (if available)
    if command -v poppunk_assign > /dev/null 2>&1; then
        echo "Using poppunk_assign command..."
        poppunk_assign --db poppunk_fit \\
                       --query assembly_list.txt \\
                       --output poppunk_assigned \\
                       --threads ${task.cpus} \\
                       --overwrite || ASSIGN_FAILED=true
    else
        echo "poppunk_assign not available, using alternative method..."
        ASSIGN_FAILED=true
    fi
    
    # If poppunk_assign failed or not available, use alternative approach
    if [ "\$ASSIGN_FAILED" = "true" ]; then
        echo "Using poppunk --use-model approach..."
        
        # Create output directory
        mkdir -p poppunk_assigned
        
        # Use the fitted model to assign clusters
        poppunk --use-model --ref-db poppunk_fit \\
                --output poppunk_assigned \\
                --threads ${task.cpus} \\
                --overwrite || {
            echo "poppunk --use-model failed, checking for existing cluster files..."
            
            # Look for cluster files in the fitted model directory
            if [ -f poppunk_fit/poppunk_fit_clusters.csv ]; then
                echo "Found clusters in fitted model, copying..."
                cp poppunk_fit/poppunk_fit_clusters.csv poppunk_assigned/
            elif [ -f poppunk_db/poppunk_db_clusters.csv ]; then
                echo "Found clusters in database, copying..."
                cp poppunk_db/poppunk_db_clusters.csv poppunk_assigned/
            else
                echo "No cluster files found. Available files:"
                find . -name "*.csv" -ls
                exit 1
            fi
        }
    fi
    
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
    echo "1. Database creation: Completed"
    echo "2. Model fitting: Completed"
    echo "3. QC check: \$([ -f qc_report.txt ] && echo 'Completed' || echo 'Skipped')"
    echo "4. Cluster assignment: Completed"
    echo "Total samples processed: \$NUM_SAMPLES"
    echo "Total clusters identified: \$(tail -n +2 clusters.csv | cut -f2 | sort -u | wc -l)"
    """
}

process PANAROO {
    tag "Panaroo_cluster_${cluster_id}"
    container 'staphb/panaroo:1.5.2'
    publishDir "${params.resultsDir}/cluster_${cluster_id}/panaroo", mode: 'copy'

    input:
    tuple val(cluster_id), path(assemblies)

    output:
    tuple val(cluster_id), path('core_gene_alignment.aln')

    when:
    assemblies.size() >= 3  // Need at least 3 genomes for meaningful analysis

    script:
    """
    # Count the number of assembly files
    assembly_count=\$(ls -1 *.{fasta,fa,fas} 2>/dev/null | wc -l)
    echo "Processing cluster ${cluster_id} with \$assembly_count genomes"
    
    # Check if we have any assembly files
    if [ \$assembly_count -eq 0 ]; then
        echo "Error: No assembly files found in working directory"
        ls -la
        exit 1
    fi
    
    # Run Panaroo pan-genome analysis
    panaroo -i *.{fasta,fa,fas} -o panaroo_output \\
            -t ${task.cpus} --clean-mode strict --aligner mafft \\
            --remove-invalid-genes
    
    # Copy core gene alignment
    if [ -f panaroo_output/core_gene_alignment.aln ]; then
        cp panaroo_output/core_gene_alignment.aln .
    else
        echo "Error: Core gene alignment not found"
        ls -la panaroo_output/
        exit 1
    fi
    
    echo "Panaroo analysis completed for cluster ${cluster_id}"
    """
}

process GUBBINS {
    tag "Gubbins_cluster_${cluster_id}"
    container 'staphb/gubbins:3.3.5'
    publishDir "${params.resultsDir}/cluster_${cluster_id}/gubbins", mode: 'copy'

    input:
    tuple val(cluster_id), path(alignment)

    output:
    tuple val(cluster_id), path('gubbins_output.filtered_polymorphic_sites.fasta')

    script:
    """
    echo "Running Gubbins on cluster ${cluster_id}"
    
    # Check alignment file
    if [ ! -f ${alignment} ]; then
        echo "Error: Alignment file not found"
        exit 1
    fi
    
    # Run Gubbins for recombination removal
    run_gubbins.py --prefix gubbins_output \\
                   --threads ${task.cpus} \\
                   --verbose ${alignment}
    
    # Check if output was created
    if [ ! -f gubbins_output.filtered_polymorphic_sites.fasta ]; then
        echo "Error: Gubbins output not found"
        ls -la gubbins_output*
        exit 1
    fi
    
    echo "Gubbins analysis completed for cluster ${cluster_id}"
    """
}

process IQTREE {
    tag "IQTree_cluster_${cluster_id}"
    container 'staphb/iqtree2:2.4.0'
    publishDir "${params.resultsDir}/cluster_${cluster_id}/iqtree", mode: 'copy'

    input:
    tuple val(cluster_id), path(snp_alignment)

    output:
    tuple val(cluster_id), path("tree.*")

    script:
    """
    echo "Building phylogenetic tree for cluster ${cluster_id}"
    
    # Check SNP alignment file
    if [ ! -f ${snp_alignment} ]; then
        echo "Error: SNP alignment file not found"
        exit 1
    fi
    
    # Check if alignment has sufficient data
    SEQ_COUNT=\$(grep -c ">" ${snp_alignment})
    if [ \$SEQ_COUNT -lt 3 ]; then
        echo "Warning: Insufficient sequences (\$SEQ_COUNT) for tree building"
        touch tree.warning
        exit 0
    fi
    
    # Build phylogenetic tree with IQ-TREE
    iqtree2 -s ${snp_alignment} -m GTR+G \\
            -nt ${task.cpus} -bb 1000 -pre tree \\
            --quiet
    
    echo "Phylogenetic tree completed for cluster ${cluster_id}"
    """
}

workflow {
    // Validate input directory
    if (!file(params.input).exists()) {
        error "Input directory does not exist: ${params.input}"
    }

    // Input channel for assemblies with debugging
    log.info "Looking for FASTA files in: ${params.input}"
    log.info "Search pattern: ${params.input}/*.{fasta,fa,fas}"
    
    assemblies_ch = Channel.fromPath("${params.input}/*.{fasta,fa,fas}")
        .ifEmpty { 
            log.error "No FASTA files found in ${params.input}"
            log.error "Checked extensions: .fasta, .fa, .fas"
            log.error "Please verify the input directory exists and contains FASTA files"
            error "No FASTA files found in ${params.input}" 
        }
        .collect()

    // Run PopPUNK clustering
    poppunk_results = POPPUNK(assemblies_ch)
    
    // Extract just the clusters.csv file from the multi-output
    clusters_csv = poppunk_results[0]  // First output is clusters.csv
    qc_report = poppunk_results[1]     // Second output is qc_report.txt (optional)

    // Parse cluster assignments and group assemblies by cluster
    cluster_assignments = clusters_csv
        .splitCsv(header: true)
        .map { row -> 
            // Try different possible column names for taxon/sample
            def taxon_name = row.Taxon ?: row.taxon ?: row.Sample ?: row.sample ?: row.ID ?: row.id
            def cluster_id = row.Cluster ?: row.cluster ?: row.cluster_id
            
            if (!taxon_name || !cluster_id) {
                error "Could not find taxon name or cluster ID in CSV row: ${row}"
            }
            
            // Try to find the assembly file with different extensions
            def assembly_file = null
            def base_name = taxon_name.toString().replaceAll(/\.(fasta|fa|fas)$/, '')
            
            ['fasta', 'fa', 'fas'].each { ext ->
                if (!assembly_file) {
                    def candidate = file("${params.input}/${base_name}.${ext}")
                    if (candidate.exists()) {
                        assembly_file = candidate
                    }
                }
            }
            
            if (!assembly_file) {
                log.warn "Could not find assembly file for taxon: ${taxon_name}"
                return null
            }
            
            return tuple(cluster_id.toString(), assembly_file)
        }
        .filter { it != null }  // Remove null entries
        .groupTuple()
        .filter { cluster_id, files -> files.size() >= 3 }  // Only process clusters with 3+ genomes

    // Log cluster information
    cluster_assignments.view { cluster_id, files -> 
        "Cluster ${cluster_id}: ${files.size()} genomes"
    }

    // Run pan-genome analysis per cluster
    panaroo_results = PANAROO(cluster_assignments)

    // Run recombination removal per cluster
    gubbins_results = GUBBINS(panaroo_results)

    // Build phylogenetic trees per cluster
    IQTREE(gubbins_results)
    
    // Summary
    IQTREE.out.view { cluster_id, tree_files ->
        "Completed analysis for cluster ${cluster_id}: ${tree_files.size()} output files"
    }
}