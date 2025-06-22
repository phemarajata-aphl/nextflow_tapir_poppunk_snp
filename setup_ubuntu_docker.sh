#!/bin/bash

# Setup script for Ubuntu Docker environment
# Fixes Docker file sharing issues with Nextflow

echo "Setting up Ubuntu Docker environment for Nextflow pipeline..."

# Create necessary directories
echo "Creating work and temp directories..."
mkdir -p ./work
mkdir -p ./tmp
mkdir -p ./results

# Set proper permissions
echo "Setting permissions..."
chmod 755 ./work
chmod 755 ./tmp
chmod 755 ./results

# Check Docker permissions
echo "Checking Docker permissions..."
if ! docker ps >/dev/null 2>&1; then
    echo "WARNING: Docker permission issue detected!"
    echo "You may need to add your user to the docker group:"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    echo "Or run with sudo (not recommended for production)"
fi

# Check available disk space
echo "Checking disk space..."
df -h .

# Set environment variables for this session
export TMPDIR="$(pwd)/tmp"
export NXF_TEMP="$(pwd)/tmp"

echo "Setup complete!"
echo ""
echo "To run the pipeline with Ubuntu Docker optimizations:"
echo "  nextflow run nextflow_tapir_poppunk_snp.nf -profile ubuntu_docker --input ./assemblies --resultsDir ./results"
echo ""
echo "Or use the standard configuration:"
echo "  nextflow run nextflow_tapir_poppunk_snp.nf --input ./assemblies --resultsDir ./results"