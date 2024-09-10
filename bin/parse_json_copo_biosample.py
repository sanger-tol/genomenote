#!/usr/bin/env python3

import argparse
import os
import json
import sys
import string
import numbers

fetch = [
    ("SPECIMEN_ID", ("SPECIMEN_ID",)),
    ("BIOSAMPLE_ACCESSION", ("biosampleAccession",)),
    ("GENUS_SPECIES", ("SCIENTIFIC_NAME",)),
    ("COMMON_NAME", ("COMMON_NAME",)),
    ("COLLECTORS", ("COLLECTED_BY",)),
    ("COLLECTOR_INSTITUTE", ("COLLECTOR_AFFILIATION",)),
    ("COLLECTOR_DATE", ("DATE_OF_COLLECTION",)),
    ("COLLECTION_METHOD", ("DESCRIPTION_OF_COLLECTION_METHOD",)),
    ("COLLECTION_LOCATION", ("COLLECTION_LOCATION",)),
    ("LATITUDE", ("DECIMAL_LATITUDE",)),
    ("HABITAT", ("HABITAT",)),
    ("IDENTIFIER", ("IDENTIFIED_BY",)),
    ("IDENTIFIER_INSTITUTE", ("IDENTIFIER_AFFILIATION",)),
    ("PRESERVATION_METHOD", ("PRESERVATION_APPROACH",)),
    ("SYMBIONT", ("SYMBIONT",)),
    ("NCBI_TAXID", ("TAXON_ID",)),
    ("ORDER", ("ORDER_OR_GROUP",)),
    ("FAMILY", ("FAMILY",)),
    ("GENUS", ("GENUS",)),
    ("SEX", ("SEX",)),
    ("LIFESTAGE", ("LIFESTAGE",)),
    ("ORGANISM_PART", ("ORGANISM_PART",)),
    ("GAL", ("GAL",)),
]


def parse_args(args=None):
    Description = "Parse contents of a COPO json file report and pul out meta data required by a genome note."
    Epilog = "Example usage: python parse_json_copo_biosample.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input JSON Assembly file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check json file -> {}".format(error)
    if context != "":
        if context_str != "":
            error_str = "ERROR: Please check json file -> {}\n{}: '{}'".format(
                error, context.strip(), context_str.strip()
            )
        else:
            error_str = "ERROR: Please check json file -> {}\n{}".format(error, context.strip())

    print(error_str)
    sys.exit(1)


def parse_json(file_in, file_out):
    try:
        with open(file_in, "r") as f:
            file = json.load(f)
        records = file.get('data', [])
    except Exception as e:
        print_error(f"Failed to read JSON file. Error: {e}")

    biosample_type = "COPO"
    param_list = []

    for data in records: 
        for f in fetch:
            param = find_element(data, f[1], index=0)
            if param is not None:
                if isinstance(param, numbers.Number):
                    param = str(param)
                if any(p in string.punctuation for p in param):
                    param = '"' + param + '"'
                # Prefix parameter name if biosample type is COPO
                param_name = f[0]
                if biosample_type == "COPO":
                    param_name = f"{biosample_type}_{param_name}"
                param_list.append([param_name, param])

    if len(param_list) > 0:
        out_dir = os.path.dirname(file_out)
        make_dir(out_dir)
        with open(file_out, "w") as fout:
            fout.write(",".join(["#paramName", "paramValue"]) + "\n")
            for param_pair in param_list:
                fout.write(",".join(param_pair) + "\n")

    else:
        print_error("No parameters found!", "File: {}".format(file_in))


def find_element(data, fields, index=0):
    if index < len(fields):
        key = fields[index]
        if key in data:
            sub_data = data[key]
            if type(sub_data) in [list, dict]:
                return find_element(sub_data, fields, index + 1)
            return sub_data
        else:
            return None
    return None


def main(args=None):
    args = parse_args(args)
    parse_json(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
