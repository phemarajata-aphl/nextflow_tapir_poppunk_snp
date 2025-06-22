#!/usr/bin/env nextflow

/*
 * Alternative PopPUNK Chunked Approach for Very Large Datasets
 * This approach splits large datasets into manageable chunks
 * Use this if the main pipeline still experiences segmentation faults
 */

nextflow.enable.dsl=2

// Default parameters for chunked approach
params.input = './assemblies'
params.resultsDir = './results'
params.chunk_size = 200  // Process 200 genomes at a time
params.overlap = 50      // Overlap between chunks for consistency

// Help message
if (params.help) {
    log.info """
    PopPUNK Chunked Alternative Pipeline
    
    Usage:
        nextflow run poppunk_chunked_alternative.nf --input <path_to_assemblies> --resultsDir <output_directory>
    
    Required arguments:
        --input         Path to directory containing FASTA assemblies
        --resultsDir    Path to output directory
    
    Optional arguments:
        --chunk_size    Number of genomes per chunk (default: 200)
        --overlap       Overlap between chunks (default: 50)
    
    Example:
        nextflow run poppunk_chunked_alternative.nf --input ./assemblies --resultsDir ./results --chunk_size 150
    """
    exit 0
}

process CHUNK_ASSEMBLIES {
    tag "Chunking_assemblies"
    
    input:
    path assemblies
    
    output:
    path "chunk_*.txt"
    
    script:
    """
    # Create chunks of assemblies
    ls *.{fasta,fa,fas} | split -l ${params.chunk_size} - chunk_
    
    # Convert to proper format for each chunk
    for chunk_file in chunk_*; do
        chunk_name=\$(basename \$chunk_file)
        while read file; do
            if [ -f "\$file" ]; then
                sample_name=\$(basename "\$file" | sed 's/\\.[^.]*\$//')
                echo -e "\$sample_name\\t\$(pwd)/\$file" >> \${chunk_name}.txt
            fi
        done < \$chunk_file
        rm \$chunk_file
    done
    
    echo "Created \$(ls chunk_*.txt | wc -l) chunks"
    """
}

process POPPUNK_CHUNK {
    tag "PopPUNK_chunk_${chunk_id}"
    container 'staphb/poppunk:2.7.5'
    memory '32 GB'
    cpus 8
    time '12h'
    
    input:
    tuple val(chunk_id), path(chunk_file)
    
    output:
    tuple val(chunk_id), path("chunk_${chunk_id}_clusters.csv")
    
    script:
    """
    echo "Processing chunk ${chunk_id} with \$(wc -l < ${chunk_file}) samples"
    
    # Create database for this chunk
    poppunk --create-db --r-files ${chunk_file} \\
            --output poppunk_db_${chunk_id} \\
            --threads ${task.cpus} \\
            --overwrite
    
    # Fit model
    poppunk --fit-model --ref-db poppunk_db_${chunk_id} \\
            --output poppunk_fit_${chunk_id} \\
            --threads ${task.cpus} \\
            --overwrite
    
    # Assign clusters
    poppunk --assign-query --ref-db poppunk_db_${chunk_id} \\
            --q-files ${chunk_file} \\
            --output poppunk_assigned_${chunk_id} \\
            --threads ${task.cpus} \\
            --overwrite
    
    # Find cluster file
    find poppunk_assigned_${chunk_id} -name "*clusters.csv" -exec cp {} chunk_${chunk_id}_clusters.csv \\;
    
    echo "Chunk ${chunk_id} completed successfully"
    """
}

process MERGE_CLUSTERS {
    tag "Merging_clusters"
    publishDir "${params.resultsDir}/poppunk", mode: 'copy'
    
    input:
    path cluster_files
    
    output:
    path "merged_clusters.csv"
    
    script:
    """
    # Merge all cluster files
    echo -e "Taxon\\tCluster" > merged_clusters.csv
    
    chunk_offset=0
    for file in ${cluster_files}; do
        if [ -f "\$file" ]; then
            echo "Processing \$file..."
            
            # Skip header and adjust cluster IDs to avoid conflicts
            tail -n +2 "\$file" | awk -v offset=\$chunk_offset 'BEGIN{FS=OFS="\\t"} {print \$1, \$2+offset}' >> merged_clusters.csv
            
            # Update offset for next chunk
            max_cluster=\$(tail -n +2 "\$file" | cut -f2 | sort -n | tail -1)
            chunk_offset=\$((chunk_offset + max_cluster + 1))
        fi
    done
    
    echo "Merged \$(tail -n +2 merged_clusters.csv | wc -l) total assignments"
    echo "Total unique clusters: \$(tail -n +2 merged_clusters.csv | cut -f2 | sort -u | wc -l)"
    """
}

workflow {
    // Input channel for assemblies
    assemblies_ch = Channel.fromPath("${params.input}/*.{fasta,fa,fas}")
        .ifEmpty { error "No FASTA files found in ${params.input}" }
        .collect()
    
    // Chunk the assemblies
    chunks = CHUNK_ASSEMBLIES(assemblies_ch)
        .flatten()
        .map { file -> 
            def chunk_id = file.name.replaceAll(/chunk_(.+)\.txt/, '$1')
            tuple(chunk_id, file)
        }
    
    // Process each chunk with PopPUNK
    chunk_results = POPPUNK_CHUNK(chunks)
    
    // Merge all cluster results
    merged_clusters = MERGE_CLUSTERS(chunk_results.map { it[1] }.collect())
    
    merged_clusters.view { "Chunked PopPUNK analysis complete: ${it}" }
}