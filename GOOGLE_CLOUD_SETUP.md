# Google Cloud Batch Setup Guide

## Prerequisites

### 1. Google Cloud Project Setup
- **Project ID**: `erudite-pod-307018`
- **Required APIs**: Batch API, Compute Engine API, Cloud Storage API
- **Service Account**: With appropriate permissions

### 2. Required Permissions
Your Google Cloud account needs the following IAM roles:
- `Batch Job Editor` or `Batch Admin`
- `Compute Instance Admin`
- `Storage Object Admin`
- `Service Account User`

### 3. Local Setup
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Authenticate
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project erudite-pod-307018
```

## Data Setup

### Input Data Location
- **Bucket**: `gs://aphlhq-ngs-gh/nextflow_data/subset_100`
- **Expected files**: FASTA assemblies (.fasta, .fa, .fas)
- **Upload command**:
```bash
gsutil -m cp ./local_assemblies/*.fasta gs://aphlhq-ngs-gh/nextflow_data/subset_100/
```

### Output Locations
- **Results**: `gs://aphlhq-ngs-gh/nextflow_data/subset_100_results`
- **Work directory**: `gs://aphlhq-ngs-gh/nextflow_work`

## Pipeline Execution

### Option 1: Automated Script (Recommended)
```bash
./run_google_batch.sh
```

### Option 2: Manual Execution
```bash
nextflow run nextflow_tapir_poppunk_snp.nf \
    -profile google_batch \
    --input gs://aphlhq-ngs-gh/nextflow_data/subset_100 \
    --resultsDir gs://aphlhq-ngs-gh/nextflow_data/subset_100_results \
    -w gs://aphlhq-ngs-gh/nextflow_work \
    -resume
```

## Google Batch Configuration

### Resource Allocation
- **PopPUNK**: 16 CPUs, 64GB RAM, n1-highmem-16 machine
- **Panaroo**: 8 CPUs, 32GB RAM, n1-standard-8 machine  
- **Gubbins**: 4 CPUs, 16GB RAM, n1-standard-4 machine
- **IQ-TREE**: 4 CPUs, 8GB RAM, n1-standard-4 machine

### Cost Optimization
- **Spot instances**: Enabled for ~70% cost savings
- **Preemptible**: Jobs can be interrupted but will resume
- **Auto-scaling**: Resources allocated only when needed

### Machine Types
```groovy
// High memory for PopPUNK clustering
machineType = 'n1-highmem-16'  // 16 vCPUs, 104 GB RAM

// Standard machines for other processes
machineType = 'n1-standard-8'  // 8 vCPUs, 30 GB RAM
machineType = 'n1-standard-4'  // 4 vCPUs, 15 GB RAM
```

## Monitoring and Troubleshooting

### Monitor Pipeline Progress
```bash
# Check running jobs
gcloud batch jobs list --location=us-central1

# View job details
gcloud batch jobs describe JOB_NAME --location=us-central1

# Check logs
gcloud logging read "resource.type=batch_job" --limit=50
```

### Common Issues

#### 1. Authentication Errors
```bash
# Re-authenticate
gcloud auth login
gcloud auth application-default login
```

#### 2. Quota Exceeded
- Check quotas in Google Cloud Console
- Request quota increases if needed
- Consider using different regions

#### 3. Bucket Access Issues
```bash
# Test bucket access
gsutil ls gs://aphlhq-ngs-gh/nextflow_data/subset_100
gsutil ls gs://aphlhq-ngs-gh/nextflow_data/subset_100_results
```

#### 4. Container Pull Issues
- Ensure Docker containers are accessible
- Check network connectivity in the region

### Cost Estimation

For 100 FASTA files (subset):
- **PopPUNK**: ~2-4 hours on n1-highmem-16 (~$8-16)
- **Panaroo**: ~1-2 hours per cluster on n1-standard-8 (~$2-4 per cluster)
- **Gubbins**: ~30-60 minutes per cluster on n1-standard-4 (~$0.50-1 per cluster)
- **IQ-TREE**: ~15-30 minutes per cluster on n1-standard-4 (~$0.25-0.50 per cluster)

**Total estimated cost**: $20-50 for 100 genomes (with spot instances)

For 400+ FASTA files:
- **PopPUNK**: ~8-16 hours on n1-highmem-16 (~$32-64)
- **Total estimated cost**: $80-150 for 400+ genomes (with spot instances)

## Results Retrieval

### View Results
```bash
# List all results
gsutil ls -r gs://aphlhq-ngs-gh/nextflow_data/subset_100_results

# Download specific results
gsutil -m cp -r gs://aphlhq-ngs-gh/nextflow_data/subset_100_results ./local_results
```

### Expected Output Structure
```
subset_100_results/
├── poppunk/                    # PopPUNK clustering results
│   └── clusters.csv           # Cluster assignments
├── cluster_1/                 # Results for cluster 1
│   ├── panaroo/              # Pan-genome analysis
│   ├── gubbins/              # Recombination removal
│   └── iqtree/               # Phylogenetic tree
├── cluster_N/                 # Results for cluster N
├── pipeline_report.html       # Execution report
├── timeline.html             # Timeline report
└── trace.txt                 # Process trace
```

## Cleanup

### Remove Work Files (Optional)
```bash
# Clean up work directory to save storage costs
gsutil -m rm -r gs://aphlhq-ngs-gh/nextflow_work
```

### Stop Running Jobs (If Needed)
```bash
# List and cancel jobs if needed
gcloud batch jobs list --location=us-central1
gcloud batch jobs delete JOB_NAME --location=us-central1
```

## Advanced Configuration

### Custom Machine Types
You can modify machine types in `nextflow.config`:
```groovy
withName: POPPUNK {
    machineType = 'n1-highmem-32'  // For very large datasets
}
```

### Different Regions
Change the location in `nextflow.config`:
```groovy
google {
    location = 'us-west1'  // or other preferred region
}
```

### Custom Disk Sizes
Adjust disk sizes for large datasets:
```groovy
withName: POPPUNK {
    disk = '500 GB'  // For very large datasets
}
```

## Security Considerations

### Service Account Setup
For production use, create a dedicated service account:
```bash
# Create service account
gcloud iam service-accounts create nextflow-batch-sa

# Grant necessary permissions
gcloud projects add-iam-policy-binding erudite-pod-307018 \
    --member="serviceAccount:nextflow-batch-sa@erudite-pod-307018.iam.gserviceaccount.com" \
    --role="roles/batch.jobsEditor"
```

### Network Security
Consider using private Google Kubernetes Engine (GKE) clusters for sensitive data.

The Google Batch profile is optimized for cloud execution with appropriate resource allocation and cost optimization features.