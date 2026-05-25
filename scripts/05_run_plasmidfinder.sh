#!/bin/bash
set -euo pipefail

# Define paths and directories
ASSEMBLY_DIR="data/assembled_genomes"
OUTPUT_DIR="results/plasmids"
# Standard Mamba/Conda target path for plasmidfinder database
DB_PATH="/home/dejenie/mambaforge/envs/amrfinder/share/plasmidfinder/data" 

mkdir -p "$OUTPUT_DIR"

echo "========================================================="
echo " Starting PlasmidFinder Replicon Profiling               "
echo "========================================================="

# Sanity Check 1: Verify database directory exists
if [ ! -d "$DB_PATH" ]; then
    echo "❌ Error: PlasmidFinder database directory not found at:"
    echo "   $DB_PATH"
    echo "   Please update DB_PATH in this script to your active database folder."
    exit 1
fi

# Sanity Check 2: Verify input FASTA directory has files
FASTA_FILES=(${ASSEMBLY_DIR}/*.fasta)
if [ ! -e "${FASTA_FILES[0]}" ]; then
    echo "❌ Error: No assembly files found in '$ASSEMBLY_DIR'"
    exit 1
fi

echo "📊 Total genomes detected: ${#FASTA_FILES[@]}"
echo "🗄️  Using Database Path: $DB_PATH"
echo "---------------------------------------------------------"

for f in "${FASTA_FILES[@]}"; do
    sample=$(basename "$f" .fasta)
    outdir="${OUTPUT_DIR}/${sample}"
    
    echo "⏱️  Profiling Plasmids for Isolate: $sample"
    mkdir -p "$outdir"
    
    # Run plasmidfinder with exact user-defined thresholds
    # -l: minimum coverage (60%), -t: minimum identity (90%), -x: enter extended output
    if plasmidfinder.py \
        -i "$f" \
        -o "$outdir" \
        -p "$DB_PATH" \
        -l 0.6 \
        -t 0.9 \
        -x; then
        echo "✅ Successfully processed: $sample"
    else
        echo "❌ Error processing: $sample" >&2
    fi
done

echo "========================================================="
echo "🎉 PlasmidFinder analysis complete! Results in $OUTPUT_DIR"
echo "========================================================="
