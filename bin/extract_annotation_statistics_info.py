#!/usr/bin/env python3
import re
import csv
import sys
import argparse


# Extract CDS information from mrna and transcript sections
def extract_cds_info(file):
    # Define regex patterns for different statistics
    patterns = {
        "TRANSC_MRNA": re.compile(r"Number of mrna\s+(\d+)"),
        "PCG": re.compile(r"Number of gene\s+(\d+)"),
        "CDS_PER_GENE": re.compile(r"mean mrnas per gene\s+([\d.]+)"),
        "EXONS_PER_TRANSC": re.compile(r"mean exons per transcript\s+([\d.]+)"),
        "CDS_LENGTH": re.compile(r"mean cds length \(bp\)\s+([\d.]+)"),
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
    non_coding_genes = {"lnc_rna": 0, "ncrna": 0, "pseudogene": 0, "snorna": 0, "snrna": 0, "rrna": 0, "trna": 0}

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


# Extract the busco score
def parse_busco_stats(busco_stats_file):
    busco_score = None
    with open(busco_stats_file, "r") as file:
        for line in file:
            if line.startswith("results.one_line_summary"):
                busco_score = line.strip()  # Store the entire summary or parse the desired part
                break
    return busco_score


# Function to write the extracted data to a CSV file
def write_to_csv(data, output_file, busco_stats_file):
    busco_score = parse_busco_stats(busco_stats_file)

    descriptions = {
        "TRANSC_MRNA": "The number of transcribed mRNAs",
        "PCG": "The number of protein coding genes",
        "NCG": "The number of non-coding genes",
        "CDS_PER_GENE": "The average number of coding transcripts per gene",
        "EXONS_PER_TRANSC": "The average number of exons per transcript",
        "CDS_LENGTH": "The average length of coding sequence",
        "EXON_SIZE": "The average length of a coding exon",
        "INTRON_SIZE": "The average length of coding intron size",
    }

    with open(output_file, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)

        # Write descriptions at the top of the CSV file
        for key, description in descriptions.items():
            csvfile.write(f"# {key}: {description}\n")

        # Write the Variable and Value columns header
        writer.writerow(["Variable", "Value"])

        # Write the data
        for key, value in data.items():
            writer.writerow([key, value])
        # Add the BUSCO score as a new line
        if busco_score:
            writer.writerow(["BUSCO_PROTEIN", busco_score])


# Main function to take input files and output file as arguments
def main():
    Description = "Parse contents of the agat_spstatistics, buscoproteins and agat_sqstatbasic to extract relevant annotation statistics information."
    Epilog = "Example usage: python extract_annotation_statistics_info.py <FILE_1> <FILE_2> <FILE_3> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_1", help="Input txt file with basic_feature_statistics.")
    parser.add_argument("FILE_2", help="Input txt file with other_feature_statistics.")
    parser.add_argument("FILE_3", help="Input file for the busco statistics.")
    parser.add_argument("FILE_OUT", help="Output file.")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    args = parser.parse_args()

    cds_info = extract_cds_info(args.FILE_2)
    non_coding_genes = extract_non_coding_genes(args.FILE_1)
    data = {**cds_info, **non_coding_genes}
    write_to_csv(data, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
