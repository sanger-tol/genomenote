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
        print("ContigN50", data["contig_n50"]["value"], sep=",", file=fout)
        print("ScaffoldN50", data["scaffold_n50"]["value"], sep=",", file=fout)

def extract_busco(file_in, file_out):
    with open(file_in, "r") as fin:
        data = json.load(fin)

    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)

    with open(file_out, "a") as fout:
        lineage = data["lineage_dataset"]["name"].upper()
        summary = data["results"]["one_line_summary"]
        print("BUSCO", '"' + lineage + ' ' + summary + '"', sep=",", file=fout)

def extract_qv(datatype, file_in, file_out):
    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)

    with open(file_in, "r") as fin, open(file_out, "a") as fout:
        data = csv.DictReader(fin, delimiter="\t")
        for row in data:
            del row["Assembly"]
            print("QV_" + datatype, row["QV"], sep=",", file=fout)

def extract_completeness(datatype, file_in, file_out):
    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)
    
    with open(file_in, "r") as fin, open(file_out, "a") as fout:
        data = csv.DictReader(fin, delimiter="\t")
        for row in data:
            print("Completeness_" + datatype, row["% Covered"], sep=",", file=fout)

def main(args=None):
    args = parse_args(args)
    extract_n50(args.N50, args.FILE_OUT)
    extract_busco(args.BUSCO, args.FILE_OUT)
    extract_qv(args.DATATYPE, args.QV, args.FILE_OUT)
    extract_completeness(args.DATATYPE, args.COMPLETENESS, args.FILE_OUT)

if __name__ == "__main__":
    sys.exit(main())
