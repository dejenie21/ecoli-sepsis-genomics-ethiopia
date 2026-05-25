#!/bin/bash
set -euo pipefail

# Standardized path setup
base_results_dir="results/plasmids"
output_dir="${base_results_dir}/combined_plasmid"
output_file="${output_dir}/combined_plasmid.csv"
tsv_name="results_tab.tsv" # Standard output file name produced by plasmidfinder.py

mkdir -p "$output_dir"

echo "========================================================="
echo " Compiling PlasmidFinder Profiles Into Unified CSV       "
echo "========================================================="

# Find the first output file to build the header structure dynamically
first_file=$(find "$base_results_dir" -mindepth 2 -maxdepth 2 -type f -name "$tsv_name" | head -n 1)

if [ -z "$first_file" ]; then
    echo "❌ Error: No per-sample '$tsv_name' files found under '$base_results_dir'."
    echo "   Did you run script 05_run_plasmidfinder.sh first?"
    exit 1
fi

echo "📊 Compiling profiles starting from template: $first_file"

{
    # Print unified master header row
    head -n 1 "$first_file" | awk 'BEGIN{FS="\t"; OFS=","} {print "sample_name", $0}'
    
    # Gather and stream data lines across all sample directories
    find "$base_results_dir" -mindepth 2 -maxdepth 2 -type f -name "$tsv_name" | sort | while read -r file; do
        # Extract the sample folder name
        sample=$(basename "$(dirname "$file")")
        echo "   -> Extracting replicons for: $sample" >&2
        
        # Skip header, sanitize internal spacing/commas, and convert tabs to commas
        tail -n +2 "$file" | awk -v sn="$sample" 'BEGIN{FS="\t"; OFS=","} {
            for (i=1; i<=NF; i++) {
                if ($i ~ /,/) $i = "\"" $i "\""
            }
            print sn, $0
        }'
    done
} > "$output_file"

# Complete Validation Check
if [ -s "$output_file" ]; then
    line_count=$(wc -l < "$output_file")
    echo "---------------------------------------------------------"
    echo "✅ Success! Plasmid profile matrix constructed."
    echo "   📍 File Destination: $output_file"
    echo "   📝 Total Entries Documented: $((line_count - 1)) plasmid rows"
    echo "========================================================="
else
    echo "❌ Error: Combined output file is empty."
    exit 1
fi
