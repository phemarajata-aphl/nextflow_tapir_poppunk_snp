#!/bin/bash -ue
# Create chunks of assemblies
ls *.{fasta,fa,fas} | split -l 200 - chunk_

# Convert to proper format for each chunk
for chunk_file in chunk_*; do
    chunk_name=$(basename $chunk_file)
    while read file; do
        if [ -f "$file" ]; then
            sample_name=$(basename "$file" | sed 's/\.[^.]*$//')
            echo -e "$sample_name\t$(pwd)/$file" >> ${chunk_name}.txt
        fi
    done < $chunk_file
    rm $chunk_file
done
