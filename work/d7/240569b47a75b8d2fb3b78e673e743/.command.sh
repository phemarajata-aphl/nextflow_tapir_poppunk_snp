#!/bin/bash -ue
echo "Processing chunk ab with $(wc -l < chunk_ab.txt) samples"

# Create database for this chunk
poppunk --create-db --r-files chunk_ab.txt \
        --output poppunk_db_ab \
        --threads 8 \
        --overwrite

# Fit model
poppunk --fit-model --ref-db poppunk_db_ab \
        --output poppunk_fit_ab \
        --threads 8 \
        --overwrite

# Assign clusters
poppunk --assign-query --ref-db poppunk_db_ab \
        --q-files chunk_ab.txt \
        --output poppunk_assigned_ab \
        --threads 8 \
        --overwrite

# Find cluster file
find poppunk_assigned_ab -name "*clusters.csv" -exec cp {} chunk_ab_clusters.csv \;
