#!/usr/bin/env python3
import re
import csv
import sys
import argparse
import json


# Extract CDS information from mrna and transcript sections
def extract_cds_info(file):
    # Define regex patterns for different statistics
    patterns = {
        "TRANSC_MRNA": re.compile(r"Number of mrna\s+(\d+)"),
        "PCG": re.compile(r"Number of gene\s+(\d+)"),
        "CDS_PER_GENE": re.compile(r"mean mrnas per gene\s+([\d.]+)"),
        "EXONS_PER_TRANSC": re.compile(r"mean exons per mrna\s+([\d.]+)"),
        "CDS_LENGTH": re.compile(r"mean mrna length \(bp\)\s+([\d.]+)"),
        "EXON_SIZE": re.compile(r"mean exon length \(bp\)\s+([\d.]+)"),
        "INTRON_SIZE": re.compile(r"mean intron in cds length \(bp\)\s+([\d.]+)"),
    }

    # Initialize a dictionary to store content for different sections
    section_content = {"mrna": "", "transcript": ""}

    # Variable to keep track of the current section being processed
    current_section = None

    with open(file, "r") as f:
        lines = f.read().splitlines()  # read all lines in the file

    for line in lines:
        line = line.strip()  # Remove any leading/trailing whitespace including newline characters

        if "---------------------------------- mrna ----------------------------------" in line:
            current_section = "mrna"  # Switch to 'mrna' section
        elif "---------------------------------- transcript ----------------------------------" in line:
            current_section = "transcript"  # Switch to 'transcript' section
        elif "----------" in line:
            current_section = None  # End of current section
        elif current_section:
            section_content[current_section] += (
                line + " "
            )  # Accumulate content for the current section, separate lines by a space

    cds_info = {}

    for label, pattern in patterns.items():
        text_to_search = section_content["mrna"] if label != "EXONS_PER_TRANSC" else section_content["transcript"]
        match = re.search(pattern, text_to_search)
        if match:
            cds_info[label] = match.group(1)

    return cds_info


# Function to extract the number of non-coding genes from the second file
def extract_non_coding_genes(file):
    non_coding_genes = {"ncrna_gene": 0}

    with open(file, "r") as f:
        for line in f:
            parts = line.split()
            if len(parts) < 2:
                continue

            gene_type = parts[0]
            try:
                count = int(parts[1])
            except ValueError:
                continue

            if gene_type in non_coding_genes:
                non_coding_genes[gene_type] += count

    NCG = sum(non_coding_genes.values())
    return {"NCG": NCG}


# Extract the one_line_summary from a BUSCO JSON file
def extract_busco_results(busco_stats_file):
    try:
        with open(busco_stats_file, "r") as file:
            busco_data = json.load(file)
            # Extract the one_line_summary from the results section
            one_line_summary = busco_data.get("results", {}).get("one_line_summary")
            if one_line_summary:
                # Use regex to extract everything after the first colon
                match = re.search(r':\s*"(.*)"', one_line_summary)
                if match:
                    one_line_summary = match.group(1)  # Get text after the colon
            return {"BUSCO_PROTEIN_SCORES": one_line_summary} if one_line_summary else {}
    except (json.JSONDecodeError, FileNotFoundError) as e:
        print(f"Error loading BUSCO JSON file: {e}")
        return {}


# Function to write the extracted data to a CSV file
def write_to_csv(data, output_file, busco_stats_file):
    busco_results = extract_busco_results(busco_stats_file)

    descriptions = {
        "TRANSC_MRNA": "The number of transcribed mRNAs",
        "PCG": "The number of protein coding genes",
        "NCG": "The number of non-coding genes",
        "CDS_PER_GENE": "The average number of coding transcripts per gene",
        "EXONS_PER_TRANSC": "The average number of exons per transcript",
        "CDS_LENGTH": "The average length of coding sequence",
        "EXON_SIZE": "The average length of a coding exon",
        "INTRON_SIZE": "The average length of coding intron size",
        "BUSCO_PROTEIN_SCORES": "BUSCO results summary from running BUSCO in protein mode",
    }

    with open(output_file, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)

        # Write descriptions at the top of the CSV file
        for key, description in descriptions.items():
            csvfile.write(f"# {key}: {description}\n")

        # Write the Variable and Value columns header
        writer.writerow(["#paramName", "paramValue"])

        # Write the data
        for key, value in data.items():
            writer.writerow([key, value])

        # Add the BUSCO results summary
        for key, value in busco_results.items():
            writer.writerow([key, value])


# Main function to take input files and output file as arguments
def main():
    Description = "Parse contents of the agat_spstatistics, buscoproteins and agat_sqstatbasic to extract relevant annotation statistics information."
    Epilog = (
        "Example usage: python extract_annotation_statistics_info.py <basic_stats> <other_stats> <busco_stats> <output>"
    )

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("basic_stats", help="Input txt file with basic_feature_statistics.")
    parser.add_argument("other_stats", help="Input txt file with other_feature_statistics.")
    parser.add_argument("busco_stats", help="Input JSON file for the BUSCO statistics.")
    parser.add_argument("output", help="Output file.")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    args = parser.parse_args()

    cds_info = extract_cds_info(args.other_stats)
    non_coding_genes = extract_non_coding_genes(args.basic_stats)
    data = {**cds_info, **non_coding_genes}
    write_to_csv(data, args.output, args.busco_stats)


if __name__ == "__main__":
    sys.exit(main())
