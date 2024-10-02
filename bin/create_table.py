#!/usr/bin/env python3

import argparse
import os
import json
import sys
import csv
import re
import math


def parse_args(args=None):
    Description = "Create a table by parsing json output to extract N50, BUSCO, QV and COMPLETENESS stats."

    parser = argparse.ArgumentParser(description=Description)
    parser.add_argument("--genome", required=True, help="Input NCBI genome summary JSON file.")
    parser.add_argument("--sequence", required=True, help="Input NCBI sequence summary JSON file.")
    parser.add_argument("--busco", help="Input BUSCO short summary JSON file.")
    parser.add_argument("--qv", nargs="*", help="Input QV TSV file from MERQURYFK.")
    parser.add_argument("--completeness", nargs="*", help="Input COMPLETENESS stats TSV file from MERQURYFK.")
    parser.add_argument("--hic", action="append", help="HiC sample ID used for contact maps.")
    parser.add_argument("--flagstat", action="append", help="HiC flagstat file created by Samtools.")
    parser.add_argument("--outcsv", required=True, help="Output CSV file.")
    parser.add_argument("--version", action="version", version="%(prog)s 3.1")
    return parser.parse_args(args)


def make_dir(path):
    """
    Creates a directory if it doesn't exist.

    Parameters:
    path (str): Path of the directory to be created.
    """
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


# check_samplesheet.py adds a suffix like "_T1", "_T2", etc, to sample names
# We usually don't want it in the final output
def remove_sample_T_suffix(name):
    """
    Removes the suffix like "_T1", "_T2", etc., from sample names.

    Parameters:
    name (str): Sample name to be processed.

    Returns:
    str: Sample name with the suffix removed.
    """
    return re.sub(r"_T\d+", "", name)


def ncbi_stats(genome_in, seq_in, writer):
    """
    Extracts and writes assembly information and statistics from genome and
    sequence JSON files to a CSV file.

    Parameters:
    genome_in (str): Path to the NCBI genome summary JSON file.
    seq_in (str): Path to the NCBI sequence summary JSON file.
    writer (csv.writer): CSV writer object to write the extracted data.
    """
    with open(genome_in, "r") as fin1:
        data = json.load(fin1)
    data = data.get("reports", [{}])[0]

    with open(seq_in, "r") as fin2:
        seq = json.load(fin2).get("reports", [])

    info = data.get("assembly_info", {})
    attr = info.get("biosample", {}).get("attributes", [])
    stats = data.get("assembly_stats", {})
    organism = data.get("organism", {})

    # Write assembly information
    writer.writerow(["##Assembly_Information"])
    writer.writerow(["Accession", data.get("accession", math.nan)])
    writer.writerow(["Common_Name", organism.get("common_name", math.nan)])
    writer.writerow(["Organism_Name", organism.get("organism_name", math.nan)])
    tol_id = "".join(pairs.get("value", "") for pairs in attr if pairs.get("name") == "tolid")
    writer.writerow(["ToL_ID", tol_id if tol_id else math.nan])
    writer.writerow(["Taxon_ID", organism.get("tax_id", math.nan)])
    writer.writerow(["Assembly_Name", info.get("assembly_name", math.nan)])
    writer.writerow(["Assembly_Level", info.get("assembly_level", math.nan)])
    life_stage = "".join(pairs.get("value", "") for pairs in attr if pairs.get("name") == "life_stage")
    writer.writerow(["Life_Stage", life_stage if life_stage else math.nan])
    tissue = "".join(pairs.get("value", "") for pairs in attr if pairs.get("name") == "tissue")
    writer.writerow(["Tissue", tissue if tissue else math.nan])
    sex = "".join(pairs.get("value", "") for pairs in attr if pairs.get("name") == "sex")
    writer.writerow(["Sex", sex if sex else math.nan])

    # Write assembly statistics
    writer.writerow(["##Assembly_Statistics"])
    writer.writerow(["Total_Sequence", stats.get("total_sequence_length", math.nan)])
    writer.writerow(["Chromosomes", stats.get("total_number_of_chromosomes", math.nan)])
    writer.writerow(["Scaffolds", stats.get("number_of_scaffolds", math.nan)])
    writer.writerow(["Scaffold_N50", stats.get("scaffold_n50", math.nan)])
    writer.writerow(["Contigs", stats.get("number_of_contigs", math.nan)])
    writer.writerow(["Contig_N50", stats.get("contig_n50", math.nan)])
    writer.writerow(["GC_Percent", stats.get("gc_percent", math.nan)])

    chromosome_header = False
    for mol in seq:
        if mol.get("gc_percent") is not None and mol.get("assembly_unit") != "non-nuclear":
            if not chromosome_header:
                writer.writerow(["##Chromosome", "Length", "GC_Percent", "Accession"])
                chromosome_header = True
            writer.writerow(
                [
                    mol.get("chr_name", math.nan),
                    round(mol.get("length", 0) / 1000000, 2) if mol.get("length") is not None else math.nan,
                    mol.get("gc_percent", math.nan),
                    mol.get("genbank_accession"),
                ]
            )

    organelle_header = False
    for mol in seq:
        if mol.get("gc_percent") is not None and mol.get("assembly_unit") == "non-nuclear":
            if not organelle_header:
                writer.writerow(["##Organelle", "Length", "GC_Percent", "Accession"])
                organelle_header = True
            writer.writerow(
                [
                    mol.get("assigned_molecule_location_type", math.nan),
                    round(mol.get("length", 0) / 1000000, 2) if mol.get("length") is not None else math.nan,
                    mol.get("gc_percent", math.nan),
                    mol.get("genbank_accession"),
                ]
            )


def extract_busco(file_in, writer):
    """
    Extracts BUSCO information from a JSON file and writes it to a CSV file.

    Parameters:
    file_in (str): Path to the BUSCO summary JSON file.
    writer (csv.writer): CSV writer object to write the extracted data.
    """
    with open(file_in, "r") as fin:
        data = json.load(fin)

    lineage_dataset_name = data.get("lineage_dataset", {}).get("name", math.nan)
    results_summary = data.get("results", {}).get("one_line_summary", math.nan)

    writer.writerow(["##BUSCO", lineage_dataset_name])
    writer.writerow(["Summary", results_summary])


def extract_pacbio(qv, completeness, writer):
    """
    Extracts QV and completeness information from TSV files and writes it to a
    CSV file.

    NOTE: completeness and qv files have to be from matching specimen names

    Parameters:
    qv (list): List of paths to one or more QV TSV files.
    completeness (list): List of paths to completeness stats TSV files.
    writer (csv.writer): CSV writer object to write the extracted data.
    """
    qval = 0
    qv_name = None
    for f in qv:
        with open(f, "r") as fin:
            data = csv.DictReader(fin, delimiter="\t")
            for row in data:
                if float(row["QV"]) > qval:
                    qval = float(row["QV"])
                    qv_name = remove_sample_T_suffix(os.path.basename(f).removesuffix(".qv"))
    assert qv_name is not None, "No QV values found in %s" % qv

    # The completeness has to be from the same specimen as the QV value
    matching_completeness_files = []
    for h in completeness:
        comp_name = remove_sample_T_suffix(os.path.basename(h).removesuffix(".completeness.stats"))
        if comp_name == qv_name:
            matching_completeness_files.append(h)
    assert matching_completeness_files, "No completeness files (%s) match for %s" % (completeness, qv_name)

    comp = None
    for h in matching_completeness_files:
        with open(h, "r") as fin:
            data = csv.DictReader(fin, delimiter="\t")
            for row in data:
                comp = float(row["% Covered"])
    assert comp is not None, "No completeness values found in %s" % matching_completeness_files

    writer.writerow(["##MerquryFK", qv_name])
    writer.writerow(["QV", qval])
    writer.writerow(["Completeness", comp])


def extract_mapped(sample, file_in, writer):
    """
    Extracts mapping information from a flagstat file and writes it to a CSV
    file.

    Parameters:
    sample (str): Sample ID used for the HiC contact maps.
    file_in (str): Path to the HiC flagstat file created by Samtools.
    writer (csv.writer): CSV writer object to write the extracted data.
    """
    writer.writerow(["##HiC", remove_sample_T_suffix(sample)])
    with open(file_in, "r") as fin:
        for line in fin:
            if "primary mapped" in line:
                writer.writerow(["Primary_Mapped", re.search(r"\((.*?) :", line).group(1)])


def main(args=None):
    args = parse_args(args)

    out_dir = os.path.dirname(args.outcsv)
    make_dir(out_dir)

    with open(args.outcsv, "w") as fout:
        writer = csv.writer(fout)
        ncbi_stats(args.genome, args.sequence, writer)
        if args.busco is not None:
            extract_busco(args.busco, writer)
        if args.qv and args.completeness is not None:
            extract_pacbio(args.qv, args.completeness, writer)
        if args.hic is not None:
            for hic, flagstat in zip(args.hic, args.flagstat):
                extract_mapped(hic, flagstat, writer)


if __name__ == "__main__":
    sys.exit(main())
