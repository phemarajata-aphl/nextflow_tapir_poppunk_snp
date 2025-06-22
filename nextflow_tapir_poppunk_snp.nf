#!/usr/bin/env nextflow

/*
 * TAPIR + PopPUNK + Per-Clade SNP Analysis (Local Docker Setup)
 * DSL2 pipeline optimized for 22 threads and 64 GB RAM on local machine with Docker
 * Optimized for processing ~400 FASTA files on Intel Core Ultra 9 185H
 * 
 * Steps:
 *   1. PopPUNK clustering of assembled genomes
 *   2. Split genomes by cluster
 *   3. For each cluster: run Panaroo → Gubbins → IQ-TREE
 *
 * Requirements:
 *   - Nextflow (v23+)
 *   - Docker installed and running locally
 *   - StaPH-B Docker images will be pulled automatically:
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
        --resultsDir    Path to output directory
    
    Optional arguments:
        --poppunk_threads   Number of threads for PopPUNK (default: 22)
        --panaroo_threads   Number of threads for Panaroo (default: 16)
        --gubbins_threads   Number of threads for Gubbins (default: 8)
        --iqtree_threads    Number of threads for IQ-TREE (default: 4)
    
    Example:
        nextflow run nextflow_tapir_poppunk_snp.nf --input ./my_assemblies --resultsDir ./my_results
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

    script:
    """
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
    
    # Create database
    poppunk --create-db --r-files assembly_list.txt \\
            --output poppunk_db --threads ${task.cpus} || exit 1
    
    # Fit model
    poppunk --fit-model --ref-db poppunk_db \\
            --output poppunk_fit --threads ${task.cpus} || exit 1
    
    # Assign clusters
    poppunk --assign-query --ref-db poppunk_db \\
            --q-files assembly_list.txt \\
            --output poppunk_assigned --threads ${task.cpus} || exit 1
    
    # Find and copy the cluster assignment file
    find poppunk_assigned -name "*clusters.csv" -exec cp {} clusters.csv \\;
    
    # If that doesn't work, try alternative names
    if [ ! -f clusters.csv ]; then
        find poppunk_assigned -name "*cluster*.csv" -exec cp {} clusters.csv \\;
    fi
    
    # Final check
    if [ ! -f clusters.csv ]; then
        echo "Could not find cluster assignment file. Available files:"
        find poppunk_assigned -name "*.csv" -ls
        exit 1
    fi
    
    echo "Cluster assignments created successfully"
    head -5 clusters.csv
    """
}

process PANAROO {
    tag "Panaroo_cluster_${cluster_id}"
    cpus params.panaroo_threads
    memory '32 GB'
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
    panaroo -i *.fasta -o panaroo_output \\
            -t ${task.cpus} --clean-mode strict --aligner mafft
    cp panaroo_output/core_gene_alignment.aln .
    """
}

process GUBBINS {
    tag "Gubbins_cluster_${cluster_id}"
    cpus params.gubbins_threads
    memory '16 GB'
    container 'staphb/gubbins:3.3.5'
    publishDir "${params.resultsDir}/cluster_${cluster_id}/gubbins", mode: 'copy'

    input:
    tuple val(cluster_id), path(alignment)

    output:
    tuple val(cluster_id), path('gubbins_output.filtered_polymorphic_sites.fasta')

    script:
    """
    run_gubbins.py --prefix gubbins_output \\
                   --threads ${task.cpus} ${alignment}
    """
}

process IQTREE {
    tag "IQTree_cluster_${cluster_id}"
    cpus params.iqtree_threads
    memory '8 GB'
    container 'staphb/iqtree2:2.4.0'
    publishDir "${params.resultsDir}/cluster_${cluster_id}/iqtree", mode: 'copy'

    input:
    tuple val(cluster_id), path(snp_alignment)

    output:
    tuple val(cluster_id), path("tree.*")

    script:
    """
    iqtree2 -s ${snp_alignment} -m GTR+G \\
            -nt ${task.cpus} -bb 1000 -pre tree
    """
}

workflow {
    // Validate input directory
    if (!file(params.input).exists()) {
        error "Input directory does not exist: ${params.input}"
    }

    // Input channel for assemblies
    assemblies_ch = Channel.fromPath("${params.input}/*.{fasta,fa,fas}")
        .ifEmpty { error "No FASTA files found in ${params.input}" }
        .collect()

    // Run PopPUNK clustering
    clusters_csv = POPPUNK(assemblies_ch)

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