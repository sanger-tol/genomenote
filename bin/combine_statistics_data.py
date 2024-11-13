#!/usr/bin/env python3

import csv
import os
import sys
import argparse
import string

files = [
    ("CONSISTENT", "in_consistent"),
    ("GENOME_STATISITCS", "in_genome_statistics"),
    ("ANNOTATION_STATISITCS", "in_annotation_statistics"),
]


def parse_args(args=None):
    Description = "Combined the parsed data file from the genome metadata subworkflow with the parsed data file from the genome statistics subworkflow."
    Epilog = "Example usage: python combine_statistics.py <FILE_IN_CONSISTENT> <FILE_IN_STATISTICS> <FILE_OUT_CONSISTENT> <FILE_OUT_INCONSISTENT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("--in_consistent", help="Input consistent params file.", required=True)
    parser.add_argument("--in_inconsistent", help="Input consistent params file.", required=True)
    parser.add_argument("--in_genome_statistics", help="Input parsed genome statistics params file.", required=True)
    parser.add_argument(
        "--in_annotation_statistics",
        help="Input parsed annotation statistics params file.",
        required=False,
        default=None,
    )
    parser.add_argument("--out_consistent", help="Output file.", required=True)
    parser.add_argument("--out_inconsistent", help="Output file.", required=True)
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def process_file(file_in, file_type, params, param_sets):
    with open(file_in, mode="r") as infile:
        reader = csv.reader(infile)

        for row in reader:
            if row[0].startswith("#"):
                continue

            key = row.pop(0)
            source_values = []

            if param_sets.get(key):
                source_values = param_sets.get(key)

            if file_type == "CONSISTENT":
                sources = row[1].split("|")
            else:
                sources = ["STATISICS"]

            value = row[0]

            if key == "CHR_TABLE":
                value = ",".join(row)

            elif any(p in string.punctuation for p in value):
                value = '"' + value + '"'

            for source in sources:
                source_values.append([source, value])

            param_sets[key] = source_values

            if key in params:
                params[key].append(value)
            else:
                params[key] = [value]

    return (params, param_sets)


def process_inconsistent_file(file, params, inconsistent, consistent):
    # Add inconsistent data from metadata_inconsistent_file
    with open(file, mode="r") as infile:
        reader = csv.reader(infile)

        for row in reader:
            if row[0] == "#paramName":
                continue
            else:
                key = row.pop(0)

                if consistent.get(key) is None:
                    inconsistent[key] = row

    return inconsistent


def main(args=None):
    args = parse_args(args)
    params = {}
    param_sets = {}
    params_inconsistent = {}

    for file in files:
        if file[0] == "ANNOTATION_STATISITCS" and args.in_annotation_statistics == None:
            continue
        else:
            (params, param_sets) = process_file(getattr(args, file[1]), file[0], params, param_sets)

    for key in params.keys():
        value_set = {v for v in params[key]}
        if len(value_set) != 1:
            params_inconsistent[key] = []

            if key in param_sets:
                for pair in param_sets[key]:
                    pair_str = pair[0] + "|" + pair[1]
                    params_inconsistent[key].append(pair_str)

    # Strip inconsitent data from parameter list
    for i in params_inconsistent.keys():
        params.pop(i)

    # combine inconsisent params and add in original data source
    params_inconsistent = process_inconsistent_file(args.in_inconsistent, param_sets, params_inconsistent, params)

    # Write out file where data is consistent across different sources
    if len(params) > 0:
        with open(args.out_consistent, "w") as fout:
            fout.write(",".join(["#paramName", "paramValue"]) + "\n")
            for key in sorted(params):
                fout.write(key + "," + params[key][0] + "\n")

    # Write out file where data is inconsistent across different sources
    with open(args.out_inconsistent, "w") as fout:
        fout.write(",".join(["#paramName", "source|paramValue"]) + "\n")
        if len(params_inconsistent) > 0:
            for key in sorted(params_inconsistent):
                fout.write(key + ",")
                fout.write(",".join(params_inconsistent[key]) + "\n")


if __name__ == "__main__":
    sys.exit(main())
