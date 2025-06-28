#!/bin/bash

echo "Testing Docker configuration fix..."

# Test basic Docker functionality
echo "1. Testing basic Docker container..."
nextflow run test_docker.nf -profile ubuntu_docker

if [ $? -eq 0 ]; then
    echo "✓ Docker configuration is working!"
    echo ""
    echo "2. You can now run your original command:"
    echo "nextflow run nextflow_tapir_poppunk_snp.nf -profile ubuntu_docker --input /mnt/disks/ngs-data/subset_100 --resultsDir /mnt/disks/ngs-data/results_322_genomes_poppunk -resume"
    echo ""
    echo "Note: Added -resume flag to continue from where it left off"
else
    echo "✗ Docker configuration still has issues. Please check Docker installation."
fi