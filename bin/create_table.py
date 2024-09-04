#!/usr/bin/env python3

import argparse
import os
import json
import sys
import csv
import re


def parse_args(args=None):
    Description = "Create a table by parsing json output to extract N50, BUSCO, QV and COMPLETENESS stats."

    parser = argparse.ArgumentParser(description=Description)
    parser.add_argument("--genome", help="Input NCBI genome summary JSON file.", required=True)
    parser.add_argument("--sequence", help="Input NCBI sequence summary JSON file.", required=True)
    parser.add_argument("--busco", help="Input BUSCO short summary JSON file.")
    parser.add_argument("--qv", nargs="*", help="Input QV TSV file from MERQURYFK.")
    parser.add_argument("--completeness", nargs="*", help="Input COMPLETENESS stats TSV file from MERQURYFK.")
    parser.add_argument("--hic", action="append", help="HiC sample ID used for contact maps.")
    parser.add_argument("--flagstat", action="append", help="HiC flagstat file created by Samtools.")
    parser.add_argument("--outcsv", help="Output CSV file.", required=True)
    parser.add_argument("--version", action="version", version="%(prog)s 3.1")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


# check_samplesheet.py adds a suffix like "_T1", "_T2", etc, to the sample names
# We usually don't want it in the final output
def remove_sample_T_suffix(name):
    return re.sub(r"_T\d+", "", name)


def ncbi_stats(genome_in, seq_in, writer):
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
    writer.writerow(["Total_Sequence", stats["total_sequence_length"]])
    if "total_number_of_chromosomes" in stats:
        writer.writerow(["Chromosomes", stats["total_number_of_chromosomes"]])
    writer.writerow(["Scaffolds", stats["number_of_scaffolds"]])
    writer.writerow(["Scaffold_N50", stats["scaffold_n50"]])
    writer.writerow(["Contigs", stats["number_of_contigs"]])
    writer.writerow(["Contig_N50", stats["contig_n50"]])
    writer.writerow(["GC_Percent", stats["gc_percent"]])
    chromosome_header = False
    for mol in seq:
        if "gc_percent" in mol and mol["assembly_unit"] != "non-nuclear":
            if not chromosome_header:
                writer.writerow(["##Chromosome", "Length", "GC_Percent", "Accession"])
                chromosome_header = True
            writer.writerow(
                [mol["chr_name"], round(mol["length"] / 1000000, 2), mol["gc_percent"], mol["genbank_accession"]]
            )
    organelle_header = False
    for mol in seq:
        if "gc_percent" in mol and mol["assembly_unit"] == "non-nuclear":
            if not organelle_header:
                writer.writerow(["##Organelle", "Length", "GC_Percent", "Accession"])
                organelle_header = True
            writer.writerow(
                [
                    mol["assigned_molecule_location_type"],
                    round(mol["length"] / 1000000, 2),
                    mol["gc_percent"],
                    mol["genbank_accession"],
                ]
            )


def extract_busco(file_in, writer):
    with open(file_in, "r") as fin:
        data = json.load(fin)

    writer.writerow(["##BUSCO", data["lineage_dataset"]["name"]])
    writer.writerow(["Summary", data["results"]["one_line_summary"]])


def extract_pacbio(qv, completeness, writer):
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
