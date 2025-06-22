# Comprehensive Troubleshooting Guide

## PopPUNK Issues

### 1. Input Format Error
**Error**: `Input reference list is misformatted. Must contain sample name and file, tab separated`

**Solution**: Fixed in current version. The pipeline automatically creates properly formatted tab-separated input files.

### 2. Segmentation Fault with Large Datasets
**Error**: `Segmentation fault` during PopPUNK execution

**Root Cause**: Memory pressure from large distance matrix calculations (quadratic growth with dataset size)

**Solutions**:
1. **Ultra-conservative settings** (automatically applied for >450 files):
   - 8 threads instead of 16+
   - 60GB memory allocation
   - Conservative PopPUNK parameters
   
2. **Monitor progress**:
   ```bash
   ./monitor_poppunk.sh
   ```

3. **Alternative chunked approach**:
   ```bash
   nextflow run poppunk_chunked_alternative.nf --input ./assemblies --resultsDir ./results --chunk_size 200
   ```

### 3. Memory Exhaustion
**Symptoms**: System becomes unresponsive, out of memory errors

**Solutions**:
1. Reduce thread count:
   ```bash
   nextflow run nextflow_tapir_poppunk_snp.nf --poppunk_threads 4
   ```

2. Use swap space:
   ```bash
   sudo fallocate -l 32G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

## Docker Issues

### 1. Permission Denied
**Error**: `permission denied while trying to connect to the Docker daemon socket`

**Solutions**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Test access
docker ps
```

### 2. Mount Point Errors
**Error**: `Mounts denied` or `Duplicate mount point`

**Solutions**:
1. Use Ubuntu Docker profile:
   ```bash
   ./setup_ubuntu_docker.sh
   nextflow run nextflow_tapir_poppunk_snp.nf -profile ubuntu_docker
   ```

2. Alternative profile:
   ```bash
   nextflow run nextflow_tapir_poppunk_snp.nf -profile local_tmp
   ```

### 3. Container Pull Failures
**Error**: `Failed to pull Docker image`

**Solutions**:
1. Check internet connectivity
2. Manually pull images:
   ```bash
   docker pull staphb/poppunk:2.7.5
   docker pull staphb/panaroo:1.5.2
   docker pull staphb/gubbins:3.3.5
   docker pull staphb/iqtree2:2.4.0
   ```

## Google Cloud Issues

### 1. Authentication Errors
**Error**: `Application Default Credentials not found`

**Solutions**:
```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project erudite-pod-307018
```

### 2. Quota Exceeded
**Error**: `Quota exceeded for resource`

**Solutions**:
1. Check quotas in Google Cloud Console
2. Request quota increases
3. Use different regions:
   ```groovy
   google {
       location = 'us-west1'
   }
   ```

### 3. Bucket Access Issues
**Error**: `Access denied to bucket`

**Solutions**:
1. Check bucket permissions:
   ```bash
   gsutil ls gs://aphlhq-ngs-gh/nextflow_data/subset_100
   ```

2. Verify service account permissions
3. Test bucket access:
   ```bash
   gsutil cp test.txt gs://aphlhq-ngs-gh/test/
   ```

### 4. Job Failures
**Error**: Jobs fail on Google Batch

**Solutions**:
1. Check job logs:
   ```bash
   gcloud batch jobs describe JOB_NAME --location=us-central1
   ```

2. Monitor resource usage
3. Increase machine types if needed

## Input Data Issues

### 1. No FASTA Files Found
**Error**: `No FASTA files found in input directory`

**Solutions**:
1. Check file extensions (.fasta, .fa, .fas)
2. Verify input path
3. List files:
   ```bash
   ls -la ./assemblies/*.{fasta,fa,fas}
   ```

### 2. Invalid FASTA Format
**Error**: Tools fail to process FASTA files

**Solutions**:
1. Validate FASTA format:
   ```bash
   head -10 assembly.fasta
   ```

2. Check for special characters in filenames
3. Ensure proper line endings (Unix format)

### 3. Empty or Corrupted Files
**Error**: Processes fail with empty input

**Solutions**:
1. Check file sizes:
   ```bash
   find ./assemblies -name "*.fasta" -size 0
   ```

2. Validate file integrity
3. Re-download corrupted files

## Performance Issues

### 1. Slow Execution
**Symptoms**: Pipeline takes much longer than expected

**Solutions**:
1. Check system resources:
   ```bash
   htop
   free -h
   df -h
   ```

2. Reduce concurrent processes:
   ```groovy
   executor {
       queueSize = 5
   }
   ```

3. Use faster storage (SSD)

### 2. High Memory Usage
**Symptoms**: System swapping, slow performance

**Solutions**:
1. Reduce thread counts
2. Process smaller batches
3. Use chunked alternative pipeline

### 3. Disk Space Issues
**Error**: `No space left on device`

**Solutions**:
1. Clean work directory:
   ```bash
   rm -rf work/
   ```

2. Use different work directory:
   ```bash
   nextflow run pipeline.nf -w /path/to/large/disk/work
   ```

## Process-Specific Issues

### Panaroo Failures
**Error**: Core gene alignment not found

**Solutions**:
1. Check minimum genome requirement (3+ genomes per cluster)
2. Verify input quality
3. Check Panaroo logs in work directory

### Gubbins Failures
**Error**: Gubbins output not found

**Solutions**:
1. Verify alignment quality
2. Check for sufficient polymorphic sites
3. Increase time limits

### IQ-TREE Failures
**Error**: Tree building fails

**Solutions**:
1. Check sequence count (minimum 3)
2. Verify alignment format
3. Try different substitution models

## Monitoring and Debugging

### 1. Real-time Monitoring
```bash
# Monitor PopPUNK progress
./monitor_poppunk.sh

# Check system resources
watch -n 5 'free -h && df -h'

# Monitor Docker containers
docker stats
```

### 2. Log Analysis
```bash
# Check Nextflow log
tail -f .nextflow.log

# Check process logs
find work -name ".command.log" -exec tail -10 {} \;

# Check error logs
find work -name ".command.err" -exec cat {} \;
```

### 3. Work Directory Investigation
```bash
# Find failed processes
find work -name ".exitcode" -exec grep -l "1" {} \;

# Check specific process
cd work/XX/XXXXXXXX
cat .command.sh
cat .command.log
cat .command.err
```

## Recovery Strategies

### 1. Resume Failed Runs
```bash
nextflow run pipeline.nf -resume
```

### 2. Restart from Specific Point
```bash
# Clean specific process cache
rm -rf work/XX/XXXXXXXX
nextflow run pipeline.nf -resume
```

### 3. Alternative Approaches
1. Use chunked pipeline for very large datasets
2. Process subsets separately
3. Use cloud execution for better resources

## Getting Help

### 1. Collect Information
Before seeking help, collect:
- Nextflow version: `nextflow -version`
- Docker version: `docker --version`
- System specs: `free -h && nproc`
- Error messages from logs
- Dataset size and characteristics

### 2. Check Documentation
- Pipeline README.md
- Google Cloud setup guide
- Nextflow documentation

### 3. Common Solutions Summary
- **Segmentation faults**: Use ultra-conservative settings or chunked approach
- **Docker issues**: Use ubuntu_docker profile and setup script
- **Memory issues**: Reduce threads and increase swap
- **Cloud issues**: Check authentication and quotas
- **Input issues**: Validate FASTA format and file paths

Most issues can be resolved by following the appropriate profile usage and resource optimization strategies outlined in this guide.