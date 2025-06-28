#!/usr/bin/env nextflow

nextflow.enable.dsl=2

process DEBUG_FILE_MATCHING {
    publishDir "debug_output", mode: 'copy'
    
    input:
    path input_dir
    path clusters_csv
    
    output:
    path 'file_matching_debug.txt'
    path 'actual_files.txt'
    path 'cluster_taxons.txt'
    path 'matching_analysis.txt'
    
    script:
    """
    echo "=== File Matching Debug Analysis ===" > file_matching_debug.txt
    echo "Input directory: ${input_dir}" >> file_matching_debug.txt
    echo "Clusters CSV: ${clusters_csv}" >> file_matching_debug.txt
    echo "" >> file_matching_debug.txt
    
    echo "=== Actual files in input directory ===" >> file_matching_debug.txt
    find ${input_dir} -name "*.fasta" -o -name "*.fa" -o -name "*.fas" | sort > actual_files.txt
    cat actual_files.txt >> file_matching_debug.txt
    echo "" >> file_matching_debug.txt
    
    echo "=== File basenames (without extension) ===" >> file_matching_debug.txt
    find ${input_dir} -name "*.fasta" -o -name "*.fa" -o -name "*.fas" | xargs -I {} basename {} | sed 's/\\.[^.]*\$//' | sort >> file_matching_debug.txt
    echo "" >> file_matching_debug.txt
    
    echo "=== Taxon names from clusters.csv ===" >> file_matching_debug.txt
    if [ -f ${clusters_csv} ]; then
        # Try different possible column names
        head -1 ${clusters_csv} >> file_matching_debug.txt
        echo "" >> file_matching_debug.txt
        
        # Extract taxon names (try different column names)
        tail -n +2 ${clusters_csv} | cut -f1 | sort > cluster_taxons.txt
        cat cluster_taxons.txt >> file_matching_debug.txt
        echo "" >> file_matching_debug.txt
        
        echo "=== Matching Analysis ===" > matching_analysis.txt
        echo "Total actual files: \$(find ${input_dir} -name "*.fasta" -o -name "*.fa" -o -name "*.fas" | wc -l)" >> matching_analysis.txt
        echo "Total taxon names: \$(tail -n +2 ${clusters_csv} | wc -l)" >> matching_analysis.txt
        echo "" >> matching_analysis.txt
        
        echo "=== Sample of mismatched taxons ===" >> matching_analysis.txt
        # Check first 10 taxon names for matches
        tail -n +2 ${clusters_csv} | cut -f1 | head -10 | while read taxon; do
            base_name=\$(echo "\$taxon" | sed 's/\\.[^.]*\$//')
            echo "Checking taxon: \$taxon (basename: \$base_name)" >> matching_analysis.txt
            
            # Try to find matching files
            found_exact=\$(find ${input_dir} -name "\${base_name}.fasta" -o -name "\${base_name}.fa" -o -name "\${base_name}.fas" | head -1)
            if [ -n "\$found_exact" ]; then
                echo "  ✅ Exact match: \$found_exact" >> matching_analysis.txt
            else
                echo "  ❌ No exact match found" >> matching_analysis.txt
                # Try partial matches
                partial_matches=\$(find ${input_dir} -name "*\${base_name}*" | head -3)
                if [ -n "\$partial_matches" ]; then
                    echo "  🔍 Partial matches:" >> matching_analysis.txt
                    echo "\$partial_matches" | sed 's/^/    /' >> matching_analysis.txt
                else
                    echo "  ❌ No partial matches found" >> matching_analysis.txt
                fi
            fi
            echo "" >> matching_analysis.txt
        done
        
        cat matching_analysis.txt >> file_matching_debug.txt
    else
        echo "Clusters CSV file not found!" >> file_matching_debug.txt
    fi
    
    echo "=== Debug analysis complete ===" >> file_matching_debug.txt
    """
}

workflow {
    // Parameters
    input_dir = params.input ?: '/mnt/disks/ngs-data/subset_100'
    clusters_csv = params.clusters ?: '/mnt/disks/ngs-data/results_322_genomes_poppunk/poppunk/clusters.csv'
    
    // Run debug analysis
    DEBUG_FILE_MATCHING(input_dir, clusters_csv)
}