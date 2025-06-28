#!/usr/bin/env nextflow

/*
 * TAPIR + PopPUNK + Per-Clade SNP Analysis Pipeline
 * DSL2 pipeline optimized for large datasets with Google Cloud Batch support
 * 
 * Steps:
 *   1. PopPUNK clustering of assembled genomes
 *   2. Prokka annotation of assemblies
 *   3. Split annotated genomes by cluster
 *   4. For each cluster: run Panaroo → Gubbins → IQ-TREE
 *
 * Requirements:
 *   - Nextflow (v23+)
 *   - Docker/Singularity containers
 *   - StaPH-B Docker images:
 *       staphb/poppunk:2.7.5 (PopPUNK clustering - latest)
 *       staphb/prokka:1.14.6 (Genome annotation - latest)
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
process CREATE_FILE_MAP {
    tag "Creating file mapping"
    publishDir "${params.resultsDir}/debug", mode: 'copy'

    input:
    path assemblies

    output:
    path 'file_mapping.txt'

    script:
    """
    echo "Creating comprehensive file mapping..."
    echo "Filename\tBasename\tFullPath" > file_mapping.txt
    
    for file in *.{fasta,fa,fas}; do
        if [ -f "\$file" ]; then
            basename_val=\$(basename "\$file" | sed 's/\\.[^.]*\$//')
            echo "\$file\t\$basename_val\t\$(pwd)/\$file" >> file_mapping.txt
        fi
    done
    
    echo "File mapping created:"
    cat file_mapping.txt
    """
}

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
    # Use the basename without extension as the sample name to ensure consistency
    for file in *.{fasta,fa,fas}; do
        if [ -f "\$file" ]; then
            # Extract sample name (remove extension) - this will be used as the taxon name
            sample_name=\$(basename "\$file" | sed 's/\\.[^.]*\$//')
            echo -e "\$sample_name\\t\$(pwd)/\$file" >> assembly_list.txt
            echo "Mapping: \$sample_name -> \$file"
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
    echo "Sample of actual filenames found:"
    ls *.{fasta,fa,fas} 2>/dev/null | head -5 || echo "No FASTA files found with these extensions"
    
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
    echo "First 10 lines of clusters.csv:"
    head -10 clusters.csv
    echo "Sample of taxon names from clusters.csv:"
    tail -n +2 clusters.csv | cut -f1 | head -10
    echo "All taxon names in clusters.csv:"
    tail -n +2 clusters.csv | cut -f1 | sort
    
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

process PROKKA {
    tag "Prokka_${sample_id}"
    container 'staphb/prokka:1.14.6'
    publishDir "${params.resultsDir}/annotations", mode: 'copy'

    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), path("${sample_id}.gff")

    script:
    """
    # Run Prokka annotation
    prokka --outdir prokka_output \\
           --prefix ${sample_id} \\
           --cpus ${task.cpus} \\
           --kingdom Bacteria \\
           --genus Burkholderia \\
           --species pseudomallei \\
           --strain ${sample_id} \\
           --locustag ${sample_id} \\
           --force \\
           ${assembly}
    
    # Copy the GFF file
    cp prokka_output/${sample_id}.gff .
    
    echo "Prokka annotation completed for ${sample_id}"
    """
}

process PANAROO {
    tag "Panaroo_cluster_${cluster_id}"
    container 'staphb/panaroo:1.5.2'
    publishDir "${params.resultsDir}/cluster_${cluster_id}/panaroo", mode: 'copy'

    input:
    tuple val(cluster_id), path(gff_files)

    output:
    tuple val(cluster_id), path('core_gene_alignment.aln')

    when:
    gff_files.size() >= 3  // Need at least 3 genomes for meaningful analysis

    script:
    """
    # Count the number of GFF files
    gff_count=\$(ls -1 *.gff 2>/dev/null | wc -l)
    echo "Processing cluster ${cluster_id} with \$gff_count annotated genomes"
    
    # Check if we have any GFF files
    if [ \$gff_count -eq 0 ]; then
        echo "Error: No GFF files found in working directory"
        ls -la
        exit 1
    fi
    
    # Run Panaroo pan-genome analysis
    panaroo -i *.gff -o panaroo_output \\
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

    // Create file mapping for debugging
    file_mapping = CREATE_FILE_MAP(assemblies_ch)
    
    // Run PopPUNK clustering
    poppunk_results = POPPUNK(assemblies_ch)
    
    // Extract just the clusters.csv file from the multi-output
    clusters_csv = poppunk_results[0]  // First output is clusters.csv
    qc_report = poppunk_results[1]     // Second output is qc_report.txt (optional)

    // Create a comprehensive list of all actual assembly files for better matching
    all_assembly_files = Channel.fromPath("${params.input}/*.{fasta,fa,fas}")
        .map { file -> 
            def basename = file.baseName
            def name_variants = [
                basename,
                basename.replaceAll('_', '.'),  // Convert underscores to dots
                basename.replaceAll('\\.', '_'), // Convert dots to underscores
                basename.replaceAll('-', '_'),   // Convert hyphens to underscores
                basename.replaceAll('_', '-')    // Convert underscores to hyphens
            ]
            return tuple(file, basename, name_variants)
        }
        .collect()

    // Parse cluster assignments with enhanced file matching
    cluster_assignments = clusters_csv
        .splitCsv(header: true)
        .combine(all_assembly_files)
        .map { row, assembly_files -> 
            // Try different possible column names for taxon/sample
            def taxon_name = row.Taxon ?: row.taxon ?: row.Sample ?: row.sample ?: row.ID ?: row.id
            def cluster_id = row.Cluster ?: row.cluster ?: row.cluster_id
            
            if (!taxon_name || !cluster_id) {
                error "Could not find taxon name or cluster ID in CSV row: ${row}"
            }
            
            // Clean up the taxon name and create variants for matching
            def base_name = taxon_name.toString().replaceAll(/\.(fasta|fa|fas)$/, '')
            def taxon_variants = [
                base_name,
                base_name.replaceAll('_', '.'),  // Convert underscores to dots
                base_name.replaceAll('\\.', '_'), // Convert dots to underscores
                base_name.replaceAll('-', '_'),   // Convert hyphens to underscores
                base_name.replaceAll('_', '-')    // Convert underscores to hyphens
            ]
            
            // Find matching assembly file using multiple strategies
            def matching_file = null
            def match_strategy = "none"
            
            // Strategy 1: Exact basename match
            if (!matching_file) {
                matching_file = assembly_files.find { file_info -> 
                    def file = file_info[0]
                    def file_basename = file_info[1]
                    return file_basename == base_name
                }
                if (matching_file) {
                    matching_file = matching_file[0]
                    match_strategy = "exact"
                }
            }
            
            // Strategy 2: Variant matching (underscores/dots/hyphens)
            if (!matching_file) {
                assembly_files.each { file_info ->
                    def file = file_info[0]
                    def file_basename = file_info[1]
                    def file_variants = file_info[2]
                    
                    // Check if any taxon variant matches any file variant
                    taxon_variants.each { taxon_variant ->
                        file_variants.each { file_variant ->
                            if (taxon_variant == file_variant && !matching_file) {
                                matching_file = file
                                match_strategy = "variant"
                            }
                        }
                    }
                }
            }
            
            // Strategy 3: Partial matching (contains)
            if (!matching_file) {
                matching_file = assembly_files.find { file_info -> 
                    def file = file_info[0]
                    def file_basename = file_info[1]
                    return taxon_variants.any { variant -> 
                        file_basename.contains(variant) || variant.contains(file_basename)
                    }
                }
                if (matching_file) {
                    matching_file = matching_file[0]
                    match_strategy = "partial"
                }
            }
            
            // Strategy 4: Fuzzy matching (remove common suffixes/prefixes)
            if (!matching_file) {
                def simplified_taxon = base_name.replaceAll(/_GCF_.*/, '').replaceAll(/_GCA_.*/, '')
                matching_file = assembly_files.find { file_info -> 
                    def file = file_info[0]
                    def file_basename = file_info[1]
                    def simplified_file = file_basename.replaceAll(/_GCF_.*/, '').replaceAll(/_GCA_.*/, '')
                    return simplified_file.contains(simplified_taxon) || simplified_taxon.contains(simplified_file)
                }
                if (matching_file) {
                    matching_file = matching_file[0]
                    match_strategy = "fuzzy"
                }
            }
            
            if (matching_file) {
                log.info "Successfully matched (${match_strategy}): ${base_name} -> ${matching_file.baseName} (cluster ${cluster_id})"
                return tuple(matching_file.baseName, matching_file, cluster_id.toString())
            } else {
                log.warn "Could not find assembly file for taxon: ${base_name}"
                log.debug "  Tried variants: ${taxon_variants}"
                return null
            }
        }
        .filter { it != null }  // Remove null entries

    // Run Prokka annotation on each assembly
    prokka_results = PROKKA(cluster_assignments.map { sample_id, assembly, cluster_id -> 
        tuple(sample_id, assembly) 
    })

    // Group annotated genomes by cluster
    cluster_gff_assignments = cluster_assignments
        .map { sample_id, assembly, cluster_id -> tuple(sample_id, cluster_id) }
        .join(prokka_results)
        .map { sample_id, cluster_id, gff_file -> tuple(cluster_id, gff_file) }
        .groupTuple()
        .filter { cluster_id, gff_files -> gff_files.size() >= 3 }  // Only process clusters with 3+ genomes

    // Log cluster information
    cluster_gff_assignments.view { cluster_id, gff_files -> 
        "Cluster ${cluster_id}: ${gff_files.size()} annotated genomes"
    }

    // Run pan-genome analysis per cluster
    panaroo_results = PANAROO(cluster_gff_assignments)

    // Run recombination removal per cluster
    gubbins_results = GUBBINS(panaroo_results)

    // Build phylogenetic trees per cluster
    IQTREE(gubbins_results)
    
    // Summary
    IQTREE.out.view { cluster_id, tree_files ->
        "Completed analysis for cluster ${cluster_id}: ${tree_files.size()} output files"
    }
    
    // Debug information
    prokka_results.view { sample_id, gff_file ->
        "Annotated ${sample_id}: ${gff_file}"
    }
}