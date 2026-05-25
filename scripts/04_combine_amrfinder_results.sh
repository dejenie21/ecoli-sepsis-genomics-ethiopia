#!/bin/bash
set -euo pipefail

input_dir="results/amr_virulence"
output_dir="${input_dir}/amrfinder_combined"
output_file="${output_dir}/amrfinder_combined.csv"

mkdir -p "$output_dir"

echo "========================================================="
echo " Combining TSV Reports Into Unified Matrix              "
echo "========================================================="

# Sanity Checks
if [ ! -d "$input_dir" ]; then
    echo "❌ Error: Input directory '$input_dir' not found"
    exit 1
fi

TSV_FILES=(${input_dir}/*_amrfinder.tsv)
if [ ! -e "${TSV_FILES[0]}" ]; then
    echo "❌ Error: No AMRFinderPlus output files found in '$input_dir'"
    exit 1
fi

# Locate primary file to construct the master header line
first_file="${TSV_FILES[0]}"
echo "📊 Compiling results across ${#TSV_FILES[@]} sample profiles..."

{
    # Generate clean CSV tracking headers
    # Converts tab separated fields to clean commas
    head -n 1 "$first_file" | awk 'BEGIN{FS="\t"; OFS=","} {print "sample_name", $0}'
    
    # Efficiently aggregate remaining output streams using optimized stream editors
    for f in "${TSV_FILES[@]}"; do
        sample=$(basename "$f" _amrfinder.tsv)
        echo "   -> Injecting metadata matrix metrics for: $sample" >&2
        
        # Skip top row header, append sample name prefix, convert interior tabs cleanly to valid commas
        tail -n +2 "$f" | awk -v sn="$sample" 'BEGIN{FS="\t"; OFS=","} {
            # Standardize string rendering to prevent cell offset breaks
            for (i=1; i<=NF; i++) {
                if ($i ~ /,/) $i = "\"" $i "\""
            }
            print sn, $0
        }'
    done
} > "$output_file"

# Validate output size metrics
if [ -s "$output_file" ]; then
    line_count=$(wc -l < "$output_file")
    echo "---------------------------------------------------------"
    echo "✅ Successfully consolidated dataset matrix!"
    echo "   📍 File Destination: $output_file"
    echo "   📝 Total Entries Documented: $((line_count - 1)) isolates rows"
    echo "========================================================="
else
    echo "❌ Error: Consolidated matrix failed to compile or generated blank outputs"
    exit 1
fi
