#!/bin/bash

# Google Cloud Storage Diagnostic Script
# Helps troubleshoot FASTA file detection issues

# Configuration
PROJECT_ID="erudite-pod-307018"
INPUT_BUCKET="gs://aphlhq-ngs-gh/nextflow_data/subset_100"

echo "Google Cloud Storage Diagnostic Tool"
echo "===================================="
echo "Project: $PROJECT_ID"
echo "Input Bucket: $INPUT_BUCKET"
echo ""

# Check authentication
echo "1. Checking Google Cloud authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ No active Google Cloud authentication found!"
    echo "Please run: gcloud auth login"
    exit 1
else
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    echo "✅ Authenticated as: $ACTIVE_ACCOUNT"
fi

# Check project
echo ""
echo "2. Checking project configuration..."
CURRENT_PROJECT=$(gcloud config get-value project)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "⚠️  Current project: $CURRENT_PROJECT"
    echo "⚠️  Expected project: $PROJECT_ID"
    echo "Setting project..."
    gcloud config set project $PROJECT_ID
else
    echo "✅ Project correctly set to: $PROJECT_ID"
fi

# Check bucket access
echo ""
echo "3. Checking bucket access..."
if gsutil ls "$INPUT_BUCKET/" >/dev/null 2>&1; then
    echo "✅ Bucket is accessible"
else
    echo "❌ Cannot access bucket: $INPUT_BUCKET"
    echo "Possible issues:"
    echo "- Bucket doesn't exist"
    echo "- No read permissions"
    echo "- Incorrect bucket name"
    exit 1
fi

# List all files in bucket
echo ""
echo "4. Listing all files in bucket..."
echo "Files found:"
gsutil ls "$INPUT_BUCKET/" | head -20

# Count files by extension
echo ""
echo "5. Counting files by extension..."

# Check .fasta files
FASTA_COUNT=$(gsutil ls "$INPUT_BUCKET/*.fasta" 2>/dev/null | wc -l)
echo ".fasta files: $FASTA_COUNT"
if [ $FASTA_COUNT -gt 0 ]; then
    echo "Sample .fasta files:"
    gsutil ls "$INPUT_BUCKET/*.fasta" | head -3
fi

# Check .fa files
FA_COUNT=$(gsutil ls "$INPUT_BUCKET/*.fa" 2>/dev/null | wc -l)
echo ".fa files: $FA_COUNT"
if [ $FA_COUNT -gt 0 ]; then
    echo "Sample .fa files:"
    gsutil ls "$INPUT_BUCKET/*.fa" | head -3
fi

# Check .fas files
FAS_COUNT=$(gsutil ls "$INPUT_BUCKET/*.fas" 2>/dev/null | wc -l)
echo ".fas files: $FAS_COUNT"
if [ $FAS_COUNT -gt 0 ]; then
    echo "Sample .fas files:"
    gsutil ls "$INPUT_BUCKET/*.fas" | head -3
fi

TOTAL_FASTA=$((FASTA_COUNT + FA_COUNT + FAS_COUNT))
echo ""
echo "Total FASTA files: $TOTAL_FASTA"

# Check for common issues
echo ""
echo "6. Checking for common issues..."

if [ $TOTAL_FASTA -eq 0 ]; then
    echo "❌ No FASTA files found!"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check if files were uploaded:"
    echo "   gsutil ls -l $INPUT_BUCKET/"
    echo ""
    echo "2. Upload FASTA files:"
    echo "   gsutil -m cp ./local_assemblies/*.fasta $INPUT_BUCKET/"
    echo ""
    echo "3. Check file extensions in bucket:"
    ALL_FILES=$(gsutil ls "$INPUT_BUCKET/" | wc -l)
    echo "   Total files in bucket: $ALL_FILES"
    if [ $ALL_FILES -gt 0 ]; then
        echo "   File extensions found:"
        gsutil ls "$INPUT_BUCKET/" | sed 's/.*\.//' | sort | uniq -c
    fi
else
    echo "✅ Found $TOTAL_FASTA FASTA files"
fi

# Test file download
echo ""
echo "7. Testing file download..."
if [ $TOTAL_FASTA -gt 0 ]; then
    FIRST_FILE=$(gsutil ls "$INPUT_BUCKET/*.{fasta,fa,fas}" 2>/dev/null | head -1)
    if [ -n "$FIRST_FILE" ]; then
        echo "Testing download of: $FIRST_FILE"
        if gsutil cp "$FIRST_FILE" ./test_download.tmp >/dev/null 2>&1; then
            FILE_SIZE=$(wc -c < ./test_download.tmp)
            echo "✅ Download successful, file size: $FILE_SIZE bytes"
            rm -f ./test_download.tmp
        else
            echo "❌ Download failed"
        fi
    fi
fi

# Summary
echo ""
echo "8. Summary and Recommendations..."
if [ $TOTAL_FASTA -eq 0 ]; then
    echo "❌ ISSUE: No FASTA files found in bucket"
    echo ""
    echo "To fix this issue:"
    echo "1. Upload your FASTA files to the bucket:"
    echo "   gsutil -m cp ./your_assemblies/*.fasta $INPUT_BUCKET/"
    echo ""
    echo "2. Verify upload:"
    echo "   gsutil ls $INPUT_BUCKET/*.fasta"
    echo ""
    echo "3. Re-run this diagnostic script to confirm"
else
    echo "✅ Ready to run pipeline!"
    echo "Command to run:"
    echo "./run_google_batch.sh"
fi