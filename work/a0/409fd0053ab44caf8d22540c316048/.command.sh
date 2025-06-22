#!/bin/bash -ue
# Aggressive memory management
ulimit -v 62914560  # ~60GB virtual memory limit
ulimit -m 62914560  # ~60GB resident memory limit
export OMP_NUM_THREADS=8
export MALLOC_TRIM_THRESHOLD_=100000
export MALLOC_MMAP_THRESHOLD_=100000

# Monitor memory usage
echo "Initial memory status:"
free -h

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

# Check dataset size and adjust parameters aggressively
NUM_SAMPLES=$(wc -l < assembly_list.txt)
echo "Processing $NUM_SAMPLES samples"

if [ $NUM_SAMPLES -gt 450 ]; then
    echo "Very large dataset detected ($NUM_SAMPLES samples). Using ultra-conservative parameters."
    SKETCH_SIZE="--sketch-size 5000"
    MIN_K="--min-k 15"
    MAX_K="--max-k 25"
    EXTRA_PARAMS="--no-stream"
elif [ $NUM_SAMPLES -gt 400 ]; then
    echo "Large dataset detected ($NUM_SAMPLES samples). Using conservative parameters."
    SKETCH_SIZE="--sketch-size 7500"
    MIN_K="--min-k 13"
    MAX_K="--max-k 29"
    EXTRA_PARAMS=""
else
    echo "Standard dataset size. Using default parameters."
    SKETCH_SIZE=""
    MIN_K=""
    MAX_K=""
    EXTRA_PARAMS=""
fi

# Memory checkpoint
echo "Memory before database creation:"
free -h

# Create database with ultra-conservative parameters for very large datasets
echo "Creating PopPUNK database..."
poppunk --create-db --r-files assembly_list.txt \
        --output poppunk_db \
        --threads 8 \
        $SKETCH_SIZE $MIN_K $MAX_K $EXTRA_PARAMS \
        --overwrite || exit 1

# Memory checkpoint
echo "Memory after database creation:"
free -h

# Fit model with memory-conscious settings
echo "Fitting PopPUNK model..."
poppunk --fit-model --ref-db poppunk_db \
        --output poppunk_fit \
        --threads 8 \
        --overwrite || exit 1

# Memory checkpoint
echo "Memory after model fitting:"
free -h

# Assign clusters
echo "Assigning clusters..."
poppunk --assign-query --ref-db poppunk_db \
        --q-files assembly_list.txt \
        --output poppunk_assigned \
        --threads 8 \
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
echo "Final memory status:"
free -h
head -5 clusters.csv
