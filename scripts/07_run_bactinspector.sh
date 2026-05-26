#!/bin/bash
set -euo pipefail

# Define operational directories
INPUT_DIR="data/trimmed_reads"
RESULTS_DIR="results"
THREADS=4 # Adjust based on your computer cores (using -p flag)

# Define precise target outputs
CHECK_OUT="${RESULTS_DIR}/check_species_result"
CLOSE_OUT="${RESULTS_DIR}/closest_match_result"

mkdir -p "$CHECK_OUT" "$CLOSE_OUT"

echo "========================================================="
echo " Starting Species Verification via BactInspector v0.1.3   "
echo "========================================================="

# Sanity Check: Verify input reads directory exists and has files
if [ ! -d "$INPUT_DIR" ]; then
    echo "❌ Error: Input directory '$INPUT_DIR' not found."
    echo "   Please make sure your trimmed reads are located there."
    exit 1
fi

# Find available files to automatically determine the file extension pattern
if ls ${INPUT_DIR}/*_1.fastq.gz >/dev/null 2>&1; then
    FILE_PATTERN="*_1.fastq.gz"
elif ls ${INPUT_DIR}/*.fastq.gz >/dev/null 2>&1; then
    FILE_PATTERN="*.fastq.gz"
elif ls ${INPUT_DIR}/*_1.fq.gz >/dev/null 2>&1; then
    FILE_PATTERN="*_1.fq.gz"
else
    FILE_PATTERN="*.fastq" # fallback
fi

echo "📊 Target file pattern identified: $FILE_PATTERN"
echo "🧵 Parallel processes allocated: $THREADS"
echo "---------------------------------------------------------"

# 1. Run check_species to verify alignment to RefSeq E. coli database matches
echo "[1/2] Running check_species..."
bactinspector check_species \
    -i "$INPUT_DIR" \
    -o "$CHECK_OUT" \
    -f "$FILE_PATTERN" \
    -p "$THREADS"

# 2. Run closest_match to isolate specific closest species coordinates
echo "[2/2] Running closest_match..."
bactinspector closest_match \
    -i "$INPUT_DIR" \
    -o "$CLOSE_OUT" \
    -f "$FILE_PATTERN" \
    -p "$THREADS"

echo "========================================================="
echo "✅ Analysis complete!"
echo "   📍 Species verification saved to: $CHECK_OUT"
echo "   📍 Closest match results saved to: $CLOSE_OUT"
echo "========================================================="
