#!/bin/bash -ue
# Set memory limits to prevent segfaults
ulimit -v 58720256  # ~56GB virtual memory limit
export OMP_NUM_THREADS=16

# Create a tab-separated list file for PopPUNK (sample_name<TAB>file_path)
for file in *.{fasta,fa,fas}; do
    if [ -f "$file" ]; then
        # Extract sample name (remove extension)
        sample_name=$(basename "$file" | sed 's/\.[^.]*$//')
        echo -e "$sample_name\t$(pwd)/$file" >> assembly_list.txt
    fi
done

# Check if we have any files
if [ ! -s assembly_list.txt ]; then
    echo "No FASTA files found!"
    exit 1
fi

echo "Found $(wc -l < assembly_list.txt) assembly files"
echo "First few entries in assembly list:"
head -3 assembly_list.txt

# Check dataset size and adjust parameters
NUM_SAMPLES=$(wc -l < assembly_list.txt)
echo "Processing $NUM_SAMPLES samples"

if [ $NUM_SAMPLES -gt 400 ]; then
    echo "Large dataset detected ($NUM_SAMPLES samples). Using conservative parameters."
    SKETCH_SIZE="--sketch-size 9999"
    MIN_K="--min-k 13"
    MAX_K="--max-k 29"
else
    echo "Standard dataset size. Using default parameters."
    SKETCH_SIZE=""
    MIN_K=""
    MAX_K=""
fi

# Create database with optimized parameters for large datasets
echo "Creating PopPUNK database..."
poppunk --create-db --r-files assembly_list.txt \
        --output poppunk_db \
        --threads 16 \
        $SKETCH_SIZE $MIN_K $MAX_K \
        --overwrite || exit 1

# Fit model with memory-conscious settings
echo "Fitting PopPUNK model..."
poppunk --fit-model --ref-db poppunk_db \
        --output poppunk_fit \
        --threads 16 \
        --overwrite || exit 1

# Assign clusters
echo "Assigning clusters..."
poppunk --assign-query --ref-db poppunk_db \
        --q-files assembly_list.txt \
        --output poppunk_assigned \
        --threads 16 \
        --overwrite || exit 1

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
echo "Total clusters found: $(tail -n +2 clusters.csv | cut -f2 | sort -u | wc -l)"
head -5 clusters.csv
