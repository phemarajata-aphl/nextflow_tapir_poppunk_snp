#!/bin/bash -ue
echo "Processing chunk aa with $(wc -l < chunk_aa.txt) samples"

# Create database for this chunk
poppunk --create-db --r-files chunk_aa.txt \
        --output poppunk_db_aa \
        --threads 8 \
        --overwrite

# Fit model
poppunk --fit-model --ref-db poppunk_db_aa \
        --output poppunk_fit_aa \
        --threads 8 \
        --overwrite

# Assign clusters
poppunk --assign-query --ref-db poppunk_db_aa \
        --q-files chunk_aa.txt \
        --output poppunk_assigned_aa \
        --threads 8 \
        --overwrite

# Find cluster file
find poppunk_assigned_aa -name "*clusters.csv" -exec cp {} chunk_aa_clusters.csv \;
