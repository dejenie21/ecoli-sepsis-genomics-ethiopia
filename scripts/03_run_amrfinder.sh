#!/bin/bash
set -euo pipefail

# Define operational directories
ASSEMBLY_DIR="data/assembled_genomes"
OUTPUT_DIR="results/amr_virulence"
DB_PATH="/home/dejenie/mambaforge/envs/amrfinder/share/amrfinderplus/data/2025-07-16.1/"
THREADS=4

mkdir -p "$OUTPUT_DIR"

echo "========================================================="
echo " Starting AMRFinderPlus Screening (Escherichia)          "
echo "========================================================="

# Sanity Check 1: Verify database version path exists locally
if [ ! -d "$DB_PATH" ]; then
    echo "❌ Error: Specified AMRFinderPlus database path not found:"
    echo "   $DB_PATH"
    exit 1
fi

# Sanity Check 2: Verify input FASTA directory has files
FASTA_FILES=(${ASSEMBLY_DIR}/*.fasta)
if [ ! -e "${FASTA_FILES[0]}" ]; then
    echo "❌ Error: No assembly files found in '$ASSEMBLY_DIR'"
    exit 1
fi

echo "📊 Total genomes detected: ${#FASTA_FILES[@]}"
echo "🗄️  Using Database Version: $DB_PATH"
echo "🧵 Threads allocated per sample: $THREADS"
echo "---------------------------------------------------------"

# Iterate across all fasta assemblies
for f in "${FASTA_FILES[@]}"; do
    base_name=$(basename "$f" .fasta)
    echo "⏱️  Processing sample: $base_name"
    
    amrfinder -n "$f" \
        -o "${OUTPUT_DIR}/${base_name}_amrfinder.tsv" \
        --organism Escherichia \
        --plus \
        --database "$DB_PATH" \
        --threads "$THREADS"
        
    echo "✅ Completed sample: $base_name"
done

echo "========================================================="
echo "🎉 All assemblies successfully screened via AMRFinderPlus"
echo "========================================================="
