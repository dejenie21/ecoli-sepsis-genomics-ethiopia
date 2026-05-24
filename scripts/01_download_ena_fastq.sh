#!/bin/bash

 set -e
 
# Script to download E. coli FASTQ files directly from ENA

# List of SRA accession numbers
accession_numbers=(
SRR17179109 SRR17179112 SRR17179119 SRR17179127 SRR17179180 SRR17179181
SRR17179190 SRR17179191 SRR17179192 SRR17179194 SRR17179197 SRR17179199
SRR17179208 SRR17179238 SRR17179239 SRR17179240 SRR17179248 SRR17179257
SRR17179279 SRR17179289 SRR17179295 SRR17179299 SRR17179302 SRR17179313
SRR17179315 SRR17179317 SRR17179320 SRR17179325 SRR17179335 SRR17179336
SRR17179339 SRR17179341 SRR17179345 SRR17179346 SRR17179348 SRR17179349
SRR17179353 SRR17179355 SRR17179356 SRR17179358 SRR17179360 SRR17179365
SRR17179366 SRR17179370 SRR17179372 SRR17179376 SRR17179378 SRR17179381
SRR17179384 SRR17179387 SRR17179390 SRR17179392 SRR17179393
)

echo "========================================"
echo "E. coli Sepsis Genome Download Script"
echo "Downloading from ENA directly"
echo "Total samples: ${#accession_numbers[@]}"
echo "========================================"

# Create a directory for downloaded files
mkdir -p data/raw_reads
cd data/raw_reads

# Function to download a single accession
download_accession() {
    local accession=$1
    echo "Processing: $accession"
    
    # Try to get the FTP links from ENA
    # First, get the run information to find FTP links
    if curl -s "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${accession}&result=read_run&fields=fastq_ftp&format=tsv" > "${accession}_info.tsv"; then
        # Extract the FTP link
        ftp_link=$(tail -n 1 "${accession}_info.tsv" | cut -f2)
        
        if [ -n "$ftp_link" ] && [ "$ftp_link" != "fastq_ftp" ]; then
            echo "Found FTP links: $ftp_link"
            
            # Split multiple links (for paired-end data)
            IFS=';' read -ra links <<< "$ftp_link"
            
            for link in "${links[@]}"; do
                if [ -n "$link" ]; then
                    filename=$(basename "$link")
                    echo "Downloading: $filename"
                    
                    # Download using wget with resume capability
                    wget -c -q --show-progress "ftp://$link"
                    
                    # Check if download was successful
                    if [ -f "$filename" ]; then
                        echo "Successfully downloaded: $filename"
                    else
                        echo "Failed to download: $filename"
                        # Try alternative method
                        echo "Trying alternative download method..."
                        wget -c -q --show-progress "https://www.ebi.ac.uk/ena/data/view/${accession}&display=download"
                    fi
                fi
            done
            
            # Clean up
            rm -f "${accession}_info.tsv"
        else
            echo "No FTP links found for $accession"
            echo "Trying alternative download method..."
            
            # Alternative method: Use the ENA browser download
            wget -c -q --show-progress "https://www.ebi.ac.uk/ena/browser/api/fasta/${accession}?download=true" -O "${accession}.fasta.gz"
            
            if [ -f "${accession}.fasta.gz" ]; then
                echo "Downloaded as FASTA: ${accession}.fasta.gz"
            else
                echo "Failed to download $accession"
            fi
        fi
    else
        echo "Failed to get information for $accession"
    fi
    
    echo "----------------------------------------"
}

# Download all accessions
for accession in "${accession_numbers[@]}"; do
    download_accession "$accession"
done

echo ""
echo "========================================"
echo "Download summary:"
echo "Files downloaded to: downloaded_fastq/"
ls -lh *.fastq.gz 2>/dev/null || echo "No FASTQ.gz files found"
ls -lh *.fasta.gz 2>/dev/null || echo "No FASTA.gz files found"
echo "========================================"
