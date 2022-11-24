#!/usr/bin/env python3

import argparse
import os
import json
import sys
import csv

def parse_args(args=None):
    Description = "Create a table by parsing json output to extract N50, BUSCO, QV and COMPLETENESS stats."

    parser = argparse.ArgumentParser(description=Description)
    parser.add_argument("SAMPLE", help="PacBio sample ID used for MerquryFK.")
    parser.add_argument("QV", help="Input QV TSV file from MERQURYFK.")
    parser.add_argument("COMPLETENESS", help="Input COMPLETENESS stats TSV file from MERQURYFK.")
    parser.add_argument("FILE_OUT", help="Output CSV file.")
    parser.add_argument('--version', action='version', version='%(prog)s 1.0')
    return parser.parse_args(args)

def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)

def extract_qv(file_in, writer):
    with open(file_in, "r") as fin:
        data = csv.DictReader(fin, delimiter="\t")
        for row in data:
            writer.writerow(["QV", row["QV"]])

def extract_completeness(file_in, writer):
    with open(file_in, "r") as fin:
        data = csv.DictReader(fin, delimiter="\t")
        for row in data:
            writer.writerow(["Completeness", row["% Covered"]])

def main(args=None):
    args = parse_args(args)

    out_dir = os.path.dirname(args.FILE_OUT)
    make_dir(out_dir)
    
    with open(args.FILE_OUT, "w") as fout:
        writer = csv.writer(fout)
        writer.writerow(["MerquryFK", args.SAMPLE])
        extract_qv(args.QV, writer)
        extract_completeness(args.COMPLETENESS, writer)

if __name__ == "__main__":
    sys.exit(main())
