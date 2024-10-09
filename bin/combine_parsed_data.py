#!/usr/bin/env python3

import csv
import os
import sys
import argparse
import string
import numbers

files = [
    ("ENA_ASSEMBLY", "ena_assembly_file"),
    ("ENA_BIOPROJECT", "ena_bioproject_file"),
    ("ENA_BIOSAMPLE", "ena_biosample_wgs_file"),
    ("ENA_BIOSAMPLE_HIC", "ena_biosample_hic_file"),
    ("ENA_BIOSAMPLE_RNA", "ena_biosample_rna_file"),
    ("ENA_TAXONOMY", "ena_taxonomy_file"),
    ("NCBI_ASSEMBLY", "ncbi_assembly_file"),
    ("NCBI_TAXONOMY", "ncbi_taxonomy_file"),
    ("GOAT_ASSEMBLY", "goat_assembly_file"),
    ("COPO_BIOSAMPLE", "copo_biosample_wgs_file"),
    ("COPO_BIOSAMPLE_HIC", "copo_biosample_hic_file"),
    ("COPO_BIOSAMPLE_RNA", "copo_biosample_rna_file"),
    ("GBIF_TAXONOMY", "gbif_taxonomy_file"),
]


def parse_args(args=None):
    Description = "Combined the parsed data files from each of the genome meta data sources."
    Epilog = "Example usage: python parse_xml_ena_bioproject.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("--ena_assembly_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--ena_bioproject_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--ena_biosample_wgs_file", help="Input parsed ENA genomic biosample file.", required=False)
    parser.add_argument("--ena_biosample_hic_file", help="Input parsed ENA HiC biosample file.", required=False)
    parser.add_argument("--ena_biosample_rna_file", help="Input parsed ENA RNASeq biosample file.", required=False)
    parser.add_argument("--ena_taxonomy_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--ncbi_assembly_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--ncbi_taxonomy_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--goat_assembly_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--copo_biosample_wgs_file", help="Input parsed COPO genomic biosample file.", required=False)
    parser.add_argument("--copo_biosample_hic_file", help="Input parsed COPO HiC biosample file.", required=False)
    parser.add_argument("--copo_biosample_rna_file", help="Input parsed COPO RNASeq biosample file.", required=False)
    parser.add_argument("--gbif_taxonomy_file", help="Input parsed GBIF taxonomy file.", required=False)
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

            if any(p in string.punctuation for p in value):
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
    locs = ["COLLECTION_LOCATION", "HIC_COLLECTION_LOCATION", "RNA_COLLECTION_LOCATION"]

    for file in files:
        # check if file exists skip if not
        if getattr(args, file[1]) is None:
            continue

        (params, paramDict) = process_file(getattr(args, file[1]), params)
        param_sets[file[0]] = paramDict

    for key in params.keys():
        value_set = {v for v in params[key]}

        # Handle collection locations having county provided by some data sources but not others
        # use longer of the two location strings
        if (key in locs) and len(value_set) == 2:
            (loc_a, loc_b) = sorted(value_set, key=len)
            if loc_b.find(loc_a):
                params[key] = [loc_b]

        if len(value_set) != 1:
            params_inconsistent[key] = []

            for source in param_sets:
                if key in param_sets[source]:
                    params_inconsistent[key].append((source, param_sets[source][key]))

    # Strip inconsistent data from parameter list
    for i in params_inconsistent.keys():
        # Don't remove locations from consistent file if one is a substring of the other, longest string is returned
        if (i in locs ) and len(params[i]) == 1:
            continue
        else:
            params.pop(i)

    # Write out file where data is consistent across different sources
    if len(params) > 0:
        with open(args.out_consistent, "w") as fout:
            fout.write(",".join(["#paramName", "paramValue"]) + "\n")
            # add in data source for consistent_params
            for key in sorted(params):
                key_sources = []
                for source in param_sets:
                    if key in param_sets[source]:
                        key_sources.append(source)
                source_list = "|".join(key_sources)
                fout.write(key + "," + params[key][0] + ',"' + source_list + '"\n')

    # Write out file where data is inconsistent across different sources
    with open(args.out_inconsistent, "w") as fout:
        fout.write(",".join(["#paramName", "source|paramValue"]) + "\n")
        if len(params_inconsistent) > 0:
            for key in sorted(params_inconsistent):
                fout.write(key + ",")
                pairs = []
                for value in params_inconsistent[key]:
                    pair = "|".join(value)
                    pairs.append(pair)

                fout.write(",".join(pairs) + "\n")


if __name__ == "__main__":
    sys.exit(main())
