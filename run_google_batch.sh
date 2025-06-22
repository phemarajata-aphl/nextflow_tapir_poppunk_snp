#!/bin/bash

# TAPIR + PopPUNK + Per-Clade SNP Analysis Pipeline
# Google Cloud Batch execution script
# Project: erudite-pod-307018

# Google Cloud configuration
PROJECT_ID="erudite-pod-307018"
INPUT_BUCKET="gs://aphlhq-ngs-gh/nextflow_data/subset_100"
RESULTS_BUCKET="gs://aphlhq-ngs-gh/nextflow_data/subset_100_results"
WORK_BUCKET="gs://aphlhq-ngs-gh/nextflow_work"

echo "TAPIR + PopPUNK + SNP Analysis Pipeline - Google Cloud Batch"
echo "============================================================"
echo "Project: $PROJECT_ID"
echo "Input: $INPUT_BUCKET"
echo "Results: $RESULTS_BUCKET"
echo "Work directory: $WORK_BUCKET"
echo ""

# Check if gcloud is configured
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "Error: No active Google Cloud authentication found!"
    echo "Please run: gcloud auth login"
    exit 1
fi

# Check if project is set correctly
CURRENT_PROJECT=$(gcloud config get-value project)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "Setting Google Cloud project to $PROJECT_ID..."
    gcloud config set project $PROJECT_ID
fi

# Enable required APIs (if not already enabled)
echo "Ensuring required Google Cloud APIs are enabled..."
gcloud services enable batch.googleapis.com --quiet
gcloud services enable compute.googleapis.com --quiet
gcloud services enable storage.googleapis.com --quiet

# Check if input bucket exists and has files
echo "Checking input data..."
FASTA_COUNT=$(gsutil ls "$INPUT_BUCKET/*.{fasta,fa,fas}" 2>/dev/null | wc -l)
if [ $FASTA_COUNT -eq 0 ]; then
    echo "Warning: No FASTA files found in $INPUT_BUCKET"
    echo "Please ensure your FASTA files are uploaded to the input bucket."
    echo "Supported extensions: .fasta, .fa, .fas"
    exit 1
fi

echo "Found $FASTA_COUNT FASTA files in input bucket"

# Create results bucket if it doesn't exist
echo "Ensuring results bucket exists..."
gsutil mb "$RESULTS_BUCKET" 2>/dev/null || echo "Results bucket already exists"

# Run the pipeline with Google Batch profile
echo "Starting pipeline execution on Google Cloud Batch..."
echo "This may take several hours for large datasets."
echo ""

nextflow run nextflow_tapir_poppunk_snp.nf \
    -profile google_batch \
    --input "$INPUT_BUCKET" \
    --resultsDir "$RESULTS_BUCKET" \
    -w "$WORK_BUCKET" \
    -resume

# Check if pipeline completed successfully
if [ $? -eq 0 ]; then
    echo ""
    echo "Pipeline completed successfully!"
    echo "Results are available in: $RESULTS_BUCKET"
    echo ""
    echo "You can view the results with:"
    echo "gsutil ls -r $RESULTS_BUCKET"
    echo ""
    echo "Download results locally with:"
    echo "gsutil -m cp -r $RESULTS_BUCKET ./local_results"
else
    echo ""
    echo "Pipeline failed! Check the error messages above."
    echo "Common issues:"
    echo "- Insufficient Google Cloud quotas"
    echo "- Authentication problems"
    echo "- Invalid input data"
    echo ""
    echo "Check the Nextflow log for details:"
    echo "cat .nextflow.log"
fi