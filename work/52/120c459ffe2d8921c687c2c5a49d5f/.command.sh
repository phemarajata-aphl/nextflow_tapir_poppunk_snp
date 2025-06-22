#!/bin/bash -ue
# Create a list file for PopPUNK with full paths
for file in *.{fasta,fa,fas}; do
    if [ -f "$file" ]; then
        echo "$(pwd)/$file" >> assembly_list.txt
    fi
done

# Check if we have any files
if [ ! -s assembly_list.txt ]; then
    echo "No FASTA files found!"
    exit 1
fi

echo "Found $(wc -l < assembly_list.txt) assembly files"

# Create database
poppunk --create-db --r-files assembly_list.txt \
        --output poppunk_db --threads 22 || exit 1

# Fit model
poppunk --fit-model --ref-db poppunk_db \
        --output poppunk_fit --threads 22 || exit 1

# Assign clusters
poppunk --assign-query --ref-db poppunk_db \
        --q-files assembly_list.txt \
        --output poppunk_assigned --threads 22 || exit 1

# Find and copy the cluster assignment file
find poppunk_assigned -name "*clusters.csv" -exec cp {} clusters.csv \;

# If that doesn't work, try alternative names
if [ ! -f clusters.csv ]; then
    find poppunk_assigned -name "*cluster*.csv" -exec cp {} clusters.csv \;
fi

# Final check
if [ ! -f clusters.csv ]; then
    echo "Could not find cluster assignment file. Available files:"
    find poppunk_assigned -name "*.csv" -ls
    exit 1
fi

echo "Cluster assignments created successfully"
head -5 clusters.csv
