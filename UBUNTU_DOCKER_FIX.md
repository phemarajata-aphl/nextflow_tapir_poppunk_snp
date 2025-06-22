# Ubuntu Docker Mount Issues - Complete Fix Guide

## Problem
When running the pipeline on Ubuntu, you may encounter this error:
```
docker: Error response from daemon: Mounts denied: 
The path /tmp/nxf.XXXXXXXXX is not shared from the host and is not known to Docker.
```

## Root Cause
This happens because:
1. Nextflow creates temporary directories in `/tmp` that Docker can't access
2. Docker on Ubuntu has stricter file sharing policies
3. The default Nextflow Docker configuration doesn't handle Ubuntu's Docker setup optimally

## Complete Solution

### Step 1: Run the Setup Script
```bash
./setup_ubuntu_docker.sh
```

This script will:
- Create proper work and temp directories
- Set correct permissions
- Check Docker access
- Set up environment variables

### Step 2: Use the Ubuntu Docker Profile
```bash
nextflow run nextflow_tapir_poppunk_snp.nf -profile ubuntu_docker --input ./assemblies --resultsDir ./results
```

### Step 3: Verify Docker Permissions
```bash
# Check if you can run Docker without sudo
docker ps

# If permission denied, add yourself to docker group
sudo usermod -aG docker $USER
newgrp docker

# Test again
docker ps
```

## What the Fix Does

### Updated Docker Configuration
```groovy
docker {
    enabled = true
    runOptions = '-u $(id -u):$(id -g) --tmpfs /tmp:rw,noexec,nosuid,size=4g'
    temp = '/tmp'
    fixOwnership = true
    remove = true
}
```

### Key Changes:
1. **`--tmpfs /tmp`**: Creates a temporary filesystem in memory for `/tmp`
2. **`fixOwnership = true`**: Ensures proper file ownership
3. **`remove = true`**: Cleans up containers after use
4. **Local work directory**: Uses `./work` instead of system temp

### Environment Variables
```bash
export TMPDIR="$(pwd)/tmp"
export NXF_TEMP="$(pwd)/tmp"
```

## Alternative Solutions

### Option 1: Use Sudo (Not Recommended)
```bash
sudo nextflow run nextflow_tapir_poppunk_snp.nf --input ./assemblies --resultsDir ./results
```

### Option 2: Manual Directory Setup
```bash
mkdir -p ./work ./tmp ./results
chmod 755 ./work ./tmp ./results
export TMPDIR="$(pwd)/tmp"
export NXF_TEMP="$(pwd)/tmp"
```

### Option 3: Docker Desktop (if available)
Install Docker Desktop which handles file sharing automatically.

## Verification

After applying the fix, test with:
```bash
# Test Docker access
docker run --rm hello-world

# Test Nextflow with Docker
nextflow run nextflow_tapir_poppunk_snp.nf --help

# Run a small test (if you have test data)
nextflow run nextflow_tapir_poppunk_snp.nf -profile ubuntu_docker --input ./test_assemblies --resultsDir ./test_results
```

## Still Having Issues?

1. **Check Docker version**: `docker --version`
2. **Check Nextflow version**: `nextflow -version`
3. **Check available disk space**: `df -h`
4. **Check Docker daemon status**: `sudo systemctl status docker`
5. **Restart Docker daemon**: `sudo systemctl restart docker`

## System Requirements Verified
- Ubuntu 18.04+ (tested)
- Docker 20.10+ (recommended)
- Nextflow 23.0+ (required)
- At least 10GB free disk space for work directory

The pipeline should now run successfully on Ubuntu with Docker!