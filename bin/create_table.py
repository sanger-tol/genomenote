#!/usr/bin/env python3

import argparse
import os
import json
import sys
import csv
import re


def parse_args(args=None):
    Description = (
        "Create a table by parsing json output to extract N50, "
        "BUSCO, QV and COMPLETENESS stats."
    )

    parser = argparse.ArgumentParser(description=Description)
    parser.add_argument(
        "--genome", required=True,
        help="Input NCBI genome summary JSON file."
    )
    parser.add_argument(
        "--sequence", required=True,
        help="Input NCBI sequence summary JSON file."
    )
    parser.add_argument(
        "--busco", help="Input BUSCO short summary JSON file."
    )
    parser.add_argument(
        "--qv", nargs="*", help="Input QV TSV file from MERQURYFK."
    )
    parser.add_argument(
        "--completeness", nargs="*",
        help="Input COMPLETENESS stats TSV file from MERQURYFK."
    )
    parser.add_argument(
        "--hic", action="append", help="HiC sample ID used for contact maps."
    )
    parser.add_argument(
        "--flagstat", action="append",
        help="HiC flagstat file created by Samtools."
    )
    parser.add_argument(
        "--outcsv", required=True, help="Output CSV file."
    )
    parser.add_argument(
        "--version", action="version", version="%(prog)s 3.1"
    )
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
    with open(seq_in, "r") as fin2:
        seq = json.load(fin2)

    data = data["reports"][0]
    info = data["assembly_info"]
    attr = info["biosample"]["attributes"]
    stats = data["assembly_stats"]
    seq = seq["reports"]

    writer.writerow(["##Assembly_Information"])
    writer.writerow(["Accession", data["accession"]])
    if "common_name" in data["organism"]:
        writer.writerow(["Common_Name", data["organism"]["common_name"]])
    writer.writerow(["Organism_Name", data["organism"]["organism_name"]])
    writer.writerow(
        [
            "ToL_ID",
            "".join(pairs["value"] for pairs in attr if pairs["name"] == "tolid"),
        ]
    )
    writer.writerow(["Taxon_ID", data["organism"]["tax_id"]])
    writer.writerow(["Assembly_Name", info["assembly_name"]])
    writer.writerow(["Assembly_Level", info["assembly_level"]])
    writer.writerow(
        [
            "Life_Stage",
            "".join(pairs["value"] for pairs in attr if pairs["name"] == "life_stage"),
        ]
    )
    writer.writerow(
        [
            "Tissue",
            "".join(pairs["value"] for pairs in attr if pairs["name"] == "tissue"),
        ]
    )
    writer.writerow(["Sex", "".join(pairs["value"] for pairs in attr if pairs["name"] == "sex")])
    writer.writerow(["##Assembly_Statistics"])
    stats.get("total_sequence_length") and writer.writerow(
        ["Total_Sequence", stats["total_sequence_length"]]
    )
    stats.get("total_number_of_chromosomes") and writer.writerow(
        ["Chromosomes", stats["total_number_of_chromosomes"]]
    )
    stats.get("number_of_scaffolds") and writer.writerow(
        ["Scaffolds", stats["number_of_scaffolds"]]
    )
    stats.get("scaffold_n50") and writer.writerow(
        ["Scaffold_N50", stats["scaffold_n50"]]
    )
    stats.get("number_of_contigs") and writer.writerow(
        ["Contigs", stats["number_of_contigs"]]
    )
    stats.get("contig_n50") and writer.writerow(
        ["Contig_N50", stats["contig_n50"]]
    )
    stats.get("gc_percent") and writer.writerow(
        ["GC_Percent", stats["gc_percent"]]
    )
    chromosome_header = False
    for mol in seq:
        if "gc_percent" in mol and mol["assembly_unit"] != "non-nuclear":
            if not chromosome_header:
                writer.writerow(["##Chromosome", "Length", "GC_Percent"])
                chromosome_header = True
            writer.writerow(
                [
                    mol["chr_name"],
                    round(mol["length"] / 1000000, 2),
                    mol["gc_percent"],
                ]
            )
    organelle_header = False
    for mol in seq:
        if "gc_percent" in mol and mol["assembly_unit"] == "non-nuclear":
            if not organelle_header:
                writer.writerow(["##Organelle", "Length", "GC_Percent"])
                organelle_header = True
            writer.writerow(
                [
                    mol["assigned_molecule_location_type"],
                    round(mol["length"] / 1000000, 2),
                    mol["gc_percent"],
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

    lineage_dataset_name = data.get("lineage_dataset", {}).get("name")
    results_summary = data.get("results", {}).get("one_line_summary")

    lineage_dataset_name and writer.writerow(["##BUSCO", lineage_dataset_name])
    results_summary and writer.writerow(["Summary", results_summary])


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
                    qv_name = remove_sample_T_suffix(
                        os.path.basename(f).removesuffix(".qv")
                    )
    assert qv_name is not None, "No QV values found in %s" % qv

    # The completeness has to be from the same specimen as the QV value
    matching_completeness_files = []
    for h in completeness:
        comp_name = remove_sample_T_suffix(
            os.path.basename(h).removesuffix(".completeness.stats")
        )
        if comp_name == qv_name:
            matching_completeness_files.append(h)
    assert matching_completeness_files, (
        "No completeness files (%s) match for %s" % (completeness, qv_name)
    )

    comp = None
    for h in matching_completeness_files:
        with open(h, "r") as fin:
            data = csv.DictReader(fin, delimiter="\t")
            for row in data:
                comp = float(row["% Covered"])
    assert comp is not None, (
        "No completeness values found in %s" % matching_completeness_files
    )

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
                writer.writerow(
                    ["Primary_Mapped", re.search(r"\((.*?) :", line).group(1)]
                )


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
