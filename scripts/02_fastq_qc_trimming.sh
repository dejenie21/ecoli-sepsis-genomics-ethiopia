#!/bin/bash
# ==============================================================
# Script: fastp_trimming.sh
# Purpose: Perform QC, adapter and quality trimming using fastp
# ==============================================================

# Input and output directories
INPUT_DIR="data/reads"
TRIMMED_DIR="data/trimmed_reads"
REPORT_DIR="data/trimmed_reads/multiqc_trimmed"
THREADS=4

# Create directories if they don’t exist
mkdir -p "${TRIMMED_DIR}" "${REPORT_DIR}"

echo "=============================================="
echo "        FASTP TRIMMING PIPELINE STARTED        "
echo "=============================================="
echo "Input reads: ${INPUT_DIR}"
echo "Output reads: ${TRIMMED_DIR}"
echo "Reports: ${REPORT_DIR}"
echo "Threads: ${THREADS}"
echo "----------------------------------------------"

# Loop through paired-end reads
for R1 in ${INPUT_DIR}/*_1.fastq.gz; do
    NAME=$(basename "${R1}" _1.fastq.gz)
    R2="${INPUT_DIR}/${NAME}_2.fastq.gz"

    echo "Processing sample: ${NAME}"

    fastp \
        -i "${R1}" \
        -I "${R2}" \
        -o "${TRIMMED_DIR}/${NAME}_1_paired.fastq.gz" \
        -O "${TRIMMED_DIR}/${NAME}_2_paired.fastq.gz" \
        --unpaired1 "${TRIMMED_DIR}/${NAME}_1_unpaired.fastq.gz" \
        --unpaired2 "${TRIMMED_DIR}/${NAME}_2_unpaired.fastq.gz" \
        --detect_adapter_for_pe \
        --qualified_quality_phred 20 \
        --unqualified_percent_limit 40 \
        --length_required 50 \
        --cut_front \
        --cut_tail \
        --cut_window_size 4 \
        --cut_mean_quality 20 \
        --trim_poly_g \
        --correction \
        -w ${THREADS} \
        -j "${REPORT_DIR}/${NAME}_fastp.json" \
        -h "${REPORT_DIR}/${NAME}_fastp.html" \
        -R "FASTP Report for ${NAME}"

    echo "✅ Completed: ${NAME}"
    echo "----------------------------------------------"
done

# Generate MultiQC summary
if command -v multiqc &> /dev/null; then
    echo "Generating MultiQC report..."
    multiqc "${REPORT_DIR}" -o "${REPORT_DIR}"
    echo "✅ MultiQC report saved in ${REPORT_DIR}/"
else
    echo "⚠️ MultiQC not found. You can install it with:"
    echo "   conda install -c bioconda multiqc"
fi

echo "=============================================="
echo "     FASTP TRIMMING PIPELINE COMPLETED         "
echo "=============================================="

