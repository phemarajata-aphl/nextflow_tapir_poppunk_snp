# Docker Mount Point Fix

## Error Fixed
```
docker: Error response from daemon: Duplicate mount point: /tmp
```

## Root Cause
This error occurs when Docker tries to mount `/tmp` multiple times due to conflicting mount configurations in the Nextflow Docker settings.

## Solution Applied

### 1. Removed Conflicting Mount Options
- Removed `--tmpfs /tmp` from Docker run options
- Simplified Docker configuration to avoid duplicate mounts

### 2. Updated Docker Configuration
```groovy
docker {
    enabled = true
    runOptions = '-u $(id -u):$(id -g)'
    temp = 'auto'
    fixOwnership = true
    remove = true
}
```

### 3. Added Multiple Profile Options

#### Option 1: Ubuntu Docker (Recommended)
```bash
nextflow run nextflow_tapir_poppunk_snp.nf -profile ubuntu_docker --input ./assemblies --resultsDir ./results
```

#### Option 2: Local Temp Directory
```bash
nextflow run nextflow_tapir_poppunk_snp.nf -profile local_tmp --input ./assemblies --resultsDir ./results
```

#### Option 3: Standard Configuration
```bash
nextflow run nextflow_tapir_poppunk_snp.nf --input ./assemblies --resultsDir ./results
```

## Quick Setup
1. Run the setup script:
   ```bash
   ./setup_ubuntu_docker.sh
   ```

2. Use the recommended profile:
   ```bash
   nextflow run nextflow_tapir_poppunk_snp.nf -profile ubuntu_docker --input ./assemblies --resultsDir ./results
   ```

## What Changed
- Removed duplicate `/tmp` mount configurations
- Set Docker temp to 'auto' to let Nextflow handle it
- Created separate profiles for different mount strategies
- Simplified Docker run options to avoid conflicts

The pipeline should now run without the "Duplicate mount point" error!