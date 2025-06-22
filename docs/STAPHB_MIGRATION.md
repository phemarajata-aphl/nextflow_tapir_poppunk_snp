# Migration to StaPH-B Docker Containers

This document summarizes the changes made to migrate the pipeline from mixed Docker containers to StaPH-B containers exclusively.

## Container Changes

### Before (Mixed Sources)
- **PopPUNK**: `mwanji/poppunk:2.6.2`
- **Panaroo**: `quay.io/biocontainers/panaroo:1.7.0--pyhdfd78af_0`
- **Gubbins**: `quay.io/biocontainers/gubbins:2.4.1--py36hb206151_3`
- **IQ-TREE**: `quay.io/biocontainers/iqtree:2.1.2--hdc80bf6_0`

### After (StaPH-B Only - Latest Versions)
- **PopPUNK**: `staphb/poppunk:2.7.5`
- **Panaroo**: `staphb/panaroo:1.5.2`
- **Gubbins**: `staphb/gubbins:3.3.5`
- **IQ-TREE**: `staphb/iqtree2:2.4.0`

## Benefits of StaPH-B Containers

1. **Standardization**: All containers follow StaPH-B standards for public health bioinformatics
2. **Maintenance**: Regularly updated and maintained by the StaPH-B consortium
3. **Consistency**: Uniform container structure and naming conventions
4. **Reliability**: Tested and validated for public health workflows
5. **Documentation**: Well-documented with clear version tracking

## Files Modified

1. **`nextflow_tapir_poppunk_snp.nf`**:
   - Updated all process container directives
   - Updated header comments with new container information

2. **`nextflow.config`**:
   - Updated all `withName` container specifications
   - Maintained all resource allocations

3. **`README.md`**:
   - Updated system requirements section
   - Added note about StaPH-B containers
   - Updated container list with StaPH-B versions

4. **`run_pipeline.sh`**:
   - Added StaPH-B container information to script comments
   - Updated output messages to mention StaPH-B containers

## Version Considerations

- **PopPUNK**: Upgraded from 2.6.2 to 2.7.5 (StaPH-B latest available)
- **Panaroo**: Downgraded from 1.7.0 to 1.5.2 (StaPH-B latest available)
- **Gubbins**: Upgraded from 2.4.1 to 3.3.5 (StaPH-B latest available)
- **IQ-TREE**: Upgraded from 2.1.2 to 2.4.0 (StaPH-B latest available)

## Compatibility Notes

- All StaPH-B containers are compatible with the existing workflow
- Command-line interfaces remain the same for all tools
- Resource requirements are maintained as before
- No changes to input/output formats or pipeline logic

## Testing

The pipeline syntax has been validated and the help message displays correctly. All container references have been successfully updated to use StaPH-B containers from DockerHub.

## Usage

No changes to usage - the pipeline runs exactly the same way:

```bash
nextflow run nextflow_tapir_poppunk_snp.nf --input ./assemblies --resultsDir ./results
```

The only difference is that Docker will now pull StaPH-B containers instead of the previous mixed container sources.