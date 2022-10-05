#!/usr/bin/env python3

import argparse
import os
import json
import sys
import csv

def parse_args(args=None):
    Description = "Create a table by parsing json output to extract N50, BUSCO, QV and COMPLETENESS stats."

    parser = argparse.ArgumentParser(description=Description)
    parser.add_argument("DATATYPE", help="Data type and kmer size for MerquryFK.")
    parser.add_argument("N50", help="Input GOAT N50 JSON file.")
    parser.add_argument("BUSCO", help="Input BUSCO short summary JSON file.")
    parser.add_argument("QV", help="Input QV TSV file from MERQURYFK.")
    parser.add_argument("COMPLETENESS", help="Input COMPLETENESS stats TSV file from MERQURYFK.")
    parser.add_argument("FILE_OUT", help="Output CSV file.")
    parser.add_argument('--version', action='version', version='%(prog)s 1.0')
    return parser.parse_args(args)

def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)

def extract_n50(file_in, file_out):
    with open(file_in, "r") as fin:
        data = json.load(fin)
        data = data["results"][0]["result"]["fields"]

    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)

    with open(file_out, "w") as fout:
        writer = csv.writer(fout)
        _ = writer.writerow(["ContigN50", data["contig_n50"]["value"]])
        _ = writer.writerow(["ScaffoldN50", data["scaffold_n50"]["value"]])

def extract_busco(file_in, file_out):
    with open(file_in, "r") as fin:
        data = json.load(fin)

    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)

    with open(file_out, "a") as fout:
        lineage = data["lineage_dataset"]["name"].upper()
        summary = data["results"]["one_line_summary"]
        writer = csv.writer(fout)
        _ = writer.writerow(["BUSCO", lineage + " " + summary])

def extract_qv(datatype, file_in, file_out):
    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)

    with open(file_in, "r") as fin, open(file_out, "a") as fout:
        data = csv.DictReader(fin, delimiter="\t")
        writer = csv.writer(fout)
        for row in data:
            _ = writer.writerow(["QV_" + datatype, row["QV"]])

def extract_completeness(datatype, file_in, writer):
    with open(file_in, "r") as fin:
        data = csv.DictReader(fin, delimiter="\t")
        for row in data:
            writer.writerow(["Completeness_" + datatype, row["% Covered"]])

def main(args=None):
    args = parse_args(args)
    out_dir = os.path.dirname(args.FILE_OUT)
    make_dir(out_dir)
    with open(args.FILE_OUT, "w") as fout:
        writer = csv.writer(fout)
        extract_n50(args.N50, writer)
        extract_busco(args.BUSCO, writer)
        extract_qv(args.DATATYPE, args.QV, writer)
        extract_completeness(args.DATATYPE, writer)

if __name__ == "__main__":
    sys.exit(main())
