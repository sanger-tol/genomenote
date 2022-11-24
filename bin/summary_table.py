#!/usr/bin/env python3

import argparse
import os
import json
import sys
import csv

def parse_args(args=None):
    Description = "Create a table by parsing json output to extract N50, BUSCO, QV and COMPLETENESS stats."

    parser = argparse.ArgumentParser(description=Description)
    parser.add_argument("NCBI", help="Input NCBI assembly summary JSON file.")
    parser.add_argument("BUSCO", help="Input BUSCO short summary JSON file.")
    parser.add_argument("FILE_OUT", help="Output CSV file.")
    parser.add_argument('--version', action='version', version='%(prog)s 1.0')
    return parser.parse_args(args)

def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)

def ncbi_stats(file_in, writer):
    with open(file_in, "r") as fin:
        data = json.load(fin)

    data = data["reports"][0]
    info = data["assembly_info"]
    attr = info["biosample"]["attributes"]
    stats = data["assembly_stats"]

    writer.writerow(["Assembly_Information"])
    writer.writerow(["Accession", data["accession"]])
    writer.writerow(["Common_Name", data["organism"]["common_name"]])
    writer.writerow(["Organism_Name", data["organism"]["organism_name"]])
    writer.writerow(["ToL_ID", "".join([ pairs["value"] for pairs in attr if pairs["name"] == "tolid" ])])
    writer.writerow(["Taxon_ID", data["organism"]["tax_id"]])
    writer.writerow(["Assembly_Name", info["assembly_name"]])
    writer.writerow(["Assembly_Level", info["assembly_level"]])
    writer.writerow(["Life_Stage", "".join([ pairs["value"] for pairs in attr if pairs["name"] == "life_stage" ])])
    writer.writerow(["Tissue", "".join([ pairs["value"] for pairs in attr if pairs["name"] == "tissue" ])])
    writer.writerow(["Organelle", ";".join([ org["description"] for org in data["organelle_info"]])])
    writer.writerow(["Assembly_Statistics"])
    writer.writerow(["Total_Sequence", stats["total_sequence_length"]])
    writer.writerow(["Chromosomes", stats["total_number_of_chromosomes"]])
    writer.writerow(["Scaffolds", stats["number_of_scaffolds"]])
    writer.writerow(["Scaffold_N50", stats["scaffold_n50"]])
    writer.writerow(["Contigs", stats["number_of_contigs"]])
    writer.writerow(["Contig_N50", stats["contig_n50"]])
    writer.writerow(["GC_Percent", stats["gc_percent"]])

def extract_busco(file_in, writer):
    with open(file_in, "r") as fin:
        data = json.load(fin)

    writer.writerow(["BUSCO"])
    writer.writerow(["Lineage", data["lineage_dataset"]["name"]])
    writer.writerow(["Summary", data["results"]["one_line_summary"]])

def main(args=None):
    args = parse_args(args)

    out_dir = os.path.dirname(args.FILE_OUT)
    make_dir(out_dir)

    with open(args.FILE_OUT, "w") as fout:
        writer = csv.writer(fout)
        ncbi_stats(args.NCBI, writer)
        extract_busco(args.BUSCO, writer)

if __name__ == "__main__":
    sys.exit(main())
