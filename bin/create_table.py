#!/usr/bin/env python3

import argparse
import os
import json
import sys

def parse_args(args=None):
    Description = "Parse json output to extract n50 values."
    Epilog = "Example usage: python extract_n50.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("N50", help="Input JSON file.")
    parser.add_argument("FILE_OUT", help="Output CSV file.")
    parser.add_argument('--version', action='version', version='%(prog)s 1.0')
    return parser.parse_args(args)

def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)

def extract_n50(file_in, file_out):
    fin = open(file_in, "r")
    data = json.load(fin)
    data = data["results"][0]["result"]["fields"]
    fin.close()

    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)
    fout = open(file_out, "w")
    print("contig_n50", data["contig_n50"]["value"], sep=",", file=fout)
    print("scaffold_n50", data["scaffold_n50"]["value"], sep=",", file=fout)
    fout.close()

def main(args=None):
    args = parse_args(args)
    extract_n50(args.N50, args.FILE_OUT)

if __name__ == "__main__":
    sys.exit(main())
