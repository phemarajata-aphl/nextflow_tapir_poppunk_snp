# Container Version Update to Latest StaPH-B Releases

## Updated Container Versions (Latest Available)

The pipeline has been updated to use the latest available StaPH-B container versions:

### Version Changes:
- **PopPUNK**: `2.6.5` → `2.7.5` ✅
- **Panaroo**: `1.5.0` → `1.5.2` ✅  
- **Gubbins**: `3.3.5` → `3.3.5` (already latest) ✅
- **IQ-TREE2**: `2.3.4` → `2.4.0` ✅

### Benefits of Latest Versions:
- **PopPUNK 2.7.5**: Latest bug fixes and performance improvements
- **Panaroo 1.5.2**: Most recent stable release with enhanced pan-genome analysis
- **Gubbins 3.3.5**: Current stable version for recombination detection
- **IQ-TREE2 2.4.0**: Latest phylogenetic inference algorithms and optimizations

### Files Updated:
1. `nextflow_tapir_poppunk_snp.nf` - Process container directives
2. `nextflow.config` - Process-specific container configurations
3. `README.md` - Documentation with updated container versions
4. `STAPHB_MIGRATION.md` - Migration documentation updated

### Compatibility:
All latest versions maintain backward compatibility with the existing pipeline workflow. No changes to command-line interfaces or input/output formats are expected.

### Testing:
- Pipeline syntax validated ✅
- Help message displays correctly ✅
- All container references updated ✅

The pipeline is ready to use with the latest StaPH-B container versions for optimal performance and latest features.