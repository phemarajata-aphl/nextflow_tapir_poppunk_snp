#!/usr/bin/env nextflow

/*
 * TAPIR + PopPUNK + Per-Clade SNP Analysis (Local Docker Setup)
 * DSL2 pipeline optimized for 22 threads and 64 GB RAM on local machine with Docker
 * Steps:
 *   1. PopPUNK clustering of assembled genomes
 *   2. Split genomes by cluster
 *   3. For each cluster: run Panaroo → Gubbins → IQ-TREE
 *
 * Requirements:
 *   - Nextflow (v23+)
 *   - Docker installed and running locally
 *   - Images:
 *       quay.io/biocontainers/panaroo:1.7.0--pyhdfd78af_0
 *       quay.io/biocontainers/gubbins:2.4.1--py36hb206151_3
 *       quay.io/biocontainers/iqtree:2.1.2--hdc80bf6_0
 *       mwanji/poppunk:2.6.2
 */

nextflow.enable.dsl=2

params {
    input      = './assemblies'         // directory containing FASTA assemblies
    resultsDir = './results'            // output directory
    threads    = 22                     // CPU threads per process
    ram        = '64 GB'                // memory per process
}

process.normal {
    executor = 'local'
    cpus     = params.threads
    memory   = params.ram
    container = ''
}

workflow {
    take:
    assemblies_ch = Channel.fromPath("${params.input}/*.fasta")

    main:
    // 1. PopPUNK clustering
    clusters_ch = poppunk(assemblies_ch)

    // 2. Split by cluster and run SNP analysis per cluster
    clusters_ch
        .groupTuple(by: { it.cluster })
        .map { cluster_id, seqs -> tuple(cluster_id, seqs.collect { it.path }) }
        .set { per_cluster }

    per_cluster.flatMap { cluster_id, paths ->
        snp_analysis(cluster_id, paths)
    }.collect()

    emit:
    val(per_cluster)
}

// Module: PopPUNK clustering
def poppunk(assembly_channel) {
    process run_poppunk {
        tag { "poppunk_${task.index}" }
        executor 'local'
        cpus params.threads
        memory params.ram
        container 'docker://mwanji/poppunk:2.6.2'
        publishDir "${params.resultsDir}/poppunk", mode: 'copy'

        input:
        path assemblies from assembly_channel.collect()

        output:
        path 'clusters.csv'

        script:
        """
        poppunk --create-db --rfiles ${assemblies.join(' ')} \
                --output poppunk_db --threads ${task.cpus}
        poppunk --fit-model --ref-db poppunk_db \
                --output poppunk_fit --threads ${task.cpus}
        poppunk --assign-query --ref-db poppunk_db \
                --qfiles ${assemblies.join(' ')} \
                --output poppunk_assigned --threads ${task.cpus}
        cp poppunk_assigned/cluster_assignments.csv clusters.csv
        """
    }

    assembly_channel
        .combine(run_poppunk.out.clusters_csv)
        .flatMap { assemblies, clusters_csv ->
            def assignments = []
            new File(clusters_csv.toString()).splitEachLine(',') { line ->
                if (line[0] != 'seqName') {
                    assignments << tuple(
                        file("${params.input}/${line[0]}.fasta"),
                        line[1].toInteger()
                    )
                }
            }
            return assignments
        }
}

// Module: SNP Analysis per cluster
def snp_analysis(cluster_id, fasta_paths) {
    Channel
        .from(fasta_paths)
        .set { cluster_seqs }

    process panaroo_cluster {
        tag "panaroo_cl${cluster_id}"
        executor 'local'
        cpus params.threads
        memory params.ram
        container 'docker://quay.io/biocontainers/panaroo:1.7.0--pyhdfd78af_0'
        publishDir "${params.resultsDir}/cluster_${cluster_id}/panaroo", mode: 'copy'

        input:
        path seqs from cluster_seqs.collect()

        output:
        path 'core_gene_alignment.aln'

        script:
        """
        panaroo -i ${seqs.join(' ')} -o panaroo_output \
                -t ${task.cpus} --clean-mode strict --aligner mafft
        cp panaroo_output/core_gene_alignment.aln .
        """
    }

    process gubbins_cluster {
        tag "gubbins_cl${cluster_id}"
        executor 'local'
        cpus params.threads
        memory params.ram
        container 'docker://quay.io/biocontainers/gubbins:2.4.1--py36hb206151_3'
        publishDir "${params.resultsDir}/cluster_${cluster_id}/gubbins", mode: 'copy'

        input:
        path aln from panaroo_cluster.out.collect().first()

        output:
        path 'gubbins_output.filtered_polymorphic_sites.fasta'

        script:
        """
        run_gubbins.py --prefix gubbins_output \
                       --threads ${task.cpus} ${aln}
        cp gubbins_output.filtered_polymorphic_sites.fasta .
        """
    }

    process iqtree_cluster {
        tag "iqtree_cl${cluster_id}"
        executor 'local'
        cpus params.threads
        memory '16 GB'
        container 'docker://quay.io/biocontainers/iqtree:2.1.2--hdc80bf6_0'
        publishDir "${params.resultsDir}/cluster_${cluster_id}/iqtree", mode: 'copy'

        input:
        path aln from gubbins_cluster.out.collect().first()

        output:
        path "tree.*"

        script:
        """
        iqtree2 -s ${aln} -m GTR+G \
                 -nt AUTO -bb 1000 -pre tree
        """
    }

    return iqtree_cluster.out
}
