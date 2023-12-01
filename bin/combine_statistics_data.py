#!/usr/bin/env python3

import csv
import os
import sys
import argparse
import string

files = [
    ("CONSISTENT", "in_consistent"),
    ("STATISITCS", "in_statistics"),
]

def parse_args(args=None):
    Description = "Combined the parsed data file from the genome metadata subworkflow with the parsed data file from the genome statistics subworkflow."
    Epilog = "Example usage: python combine_statistics.py <FILE_IN_CONSISTENT> <FILE_IN_STATISTICS> <FILE_OUT_CONSISTENT> <FILE_OUT_INCONSISTENT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("--in_consistent", help="Input consistent params file.", required=True)
    parser.add_argument("--in_statistics", help="Input parsed genome statistics params file.", required=True)
    parser.add_argument("--out_consistent", help="Output file.", required=True)
    parser.add_argument("--out_inconsistent", help="Output file.", required=True)
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def process_file(file_in, params):
    with open(file_in, mode="r") as infile:
        reader = csv.reader(infile)

        source_dict = {}
        for row in reader:
            if row[0] == "#paramName":
                continue

            key = row.pop(0)    
            value = row[0]
            
            if key == "CHR_TABLE":
                value = ",".join(row)
            
            elif any(p in string.punctuation for p in value):
                value = '"' + value + '"'

            source_dict[key] = value

            if key in params:
                params[key].append(value)
            else:
                params[key] = [value]

    return (params, source_dict)


def main(args=None):
    args = parse_args(args)
    params = {}
    param_sets = {}
    params_inconsistent = {}

    for file in files:
        (params, paramDict) = process_file(getattr(args, file[1]), params)
        param_sets[file[0]] = paramDict
        

    for key in params.keys():
        value_set = {v for v in params[key]}
        if len(value_set) != 1:
            params_inconsistent[key] = []

            for source in param_sets:
                if key in param_sets[source]:
                    params_inconsistent[key].append((source, param_sets[source][key]))

    # Strip inconsitent data from parameter list
    for i in params_inconsistent.keys():
        params.pop(i)

    # Write out file where data is consistent across different sources
    if len(params) > 0:
        with open(args.out_consistent, "w") as fout:
            fout.write(",".join(["#paramName", "paramValue"]) + "\n")
            for key in sorted(params):
                fout.write(key + "," + params[key][0] + "\n")

    # Write out file where data is inconsistent across different sources
    if len(params_inconsistent) > 0:
        with open(args.out_inconsistent, "w") as fout:
            fout.write(",".join(["#paramName", "source|paramValue"]) + "\n")
            for key in sorted(params_inconsistent):
                fout.write(key + ",")
                pairs = []
                for value in params_inconsistent[key]:
                    pair = "|".join(value)
                    pairs.append(pair)

                fout.write(",".join(pairs) + "\n")


if __name__ == "__main__":
    sys.exit(main())
