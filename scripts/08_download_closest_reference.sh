#!/bin/bash
set -euo pipefail

# Define standardized directories
CLOSE_OUT_DIR="results/closest_match_result"
REF_DIR="data/references"

mkdir -p "$REF_DIR"

echo "========================================================="
echo " Fetching Closest Reference Genome via BactInspector Log  "
echo "========================================================="

# Sanity Check 1: Verify the BactInspector output folder exists
if [ ! -d "$CLOSE_OUT_DIR" ]; then
    echo "❌ Error: BactInspector closest_match directory not found: '$CLOSE_OUT_DIR'"
    echo "   Please execute script 07_run_bactinspector.sh first."
    exit 1
fi

# Locate the closest matches TSV report dynamically
TSV_FILE=$(find "$CLOSE_OUT_DIR" -maxdepth 1 -name "closest_matches_*.tsv" | head -n 1)

if [ -z "$TSV_FILE" ] || [ ! -f "$TSV_FILE" ]; then
    echo "❌ Error: Could not locate the 'closest_matches_YYYY_MM_DD.tsv' report inside '$CLOSE_OUT_DIR'."
    exit 1
fi

echo "📊 Analyzing closest match mapping log: $TSV_FILE"

# Step 1: Extract the FTP download path from the 2nd row (top reference match hit)
echo "🔍 Extracting reference genome coordinates..."
raw_ftp_path=$(awk -F'\t' 'NR==2 {for(i=1;i<=NF;i++) if($i ~ /^ftp:\/\//) print $i}' "$TSV_FILE")

if [ -z "$raw_ftp_path" ]; then
    # Fallback if parsing fails by index column: look for any valid string containing ftp://
    raw_ftp_path=$(sed -n '2p' "$TSV_FILE" | grep -o 'ftp\:\/\/[^[:space:]]*\.gz' || true)
fi

if [ -z "$raw_ftp_path" ]; then
    echo "❌ Error: Failed to extract a valid NCBI FTP download link from row 2 of the report."
    exit 1
fi

echo "🌐 Reference target located: $raw_ftp_path"

# Handle network proxy modifications if necessary (convert ftp:// to https:// to pass firewalls easily)
download_url=$(echo "$raw_ftp_path" | sed 's|^ftp://|https://|')

# Step 2: Download the reference file directly to our reference destination
echo "📥 Downloading reference genome assembly from NCBI..."
cd "$REF_DIR"

# Clean out old failed downloads if present
rm -f *.gz *.fna

if ! wget -q --show-progress "$download_url"; then
    echo "⚠️  HTTPS download failed. Attempting alternative raw FTP protocol route..."
    wget -q --show-progress "$raw_ftp_path"
fi

# Step 3: Decompress the assembly file safely
echo "🔓 Decompressing sequence parameters..."
gunzip *.gz

# Locate the extracted sequence file (usually ends in .fna or .fasta)
ref_file=$(ls *.fna 2>/dev/null || ls *.fasta 2>/dev/null || head -n 1)

if [ -z "$ref_file" ]; then
    echo "❌ Error: Failed to locate decompressed genome assembly file."
    exit 1
fi

# Step 4: Retain only the main chromosome sequence (isolates row headers before second chromosome/plasmid block)
echo "🧬 Isolating main structural chromosome element (removing auxiliary contigs)..."
awk '/^>/{n++} n>1{exit} {print}' "$ref_file" > reference.fas

# Clean up raw intermediate uncompressed files to save disk footprint space
rm "$ref_file"

echo "========================================================="
echo "✅ Closest reference assembly successfully prepared!"
echo "   📍 Reference Path Location: ${REF_DIR}/reference.fas"
echo "========================================================="
