#!/usr/bin/env python3

import argparse
import os
import json
import sys
import string
import numbers

fetch = [
    ("BIOPROJECT_ACCESSION", ("record", "attributes", "bioproject", "value"), {"index": 0}),
    (
        "ASSEMBLY_ACCESSION",
        (
            "record",
            "assembly_id",
        ),
    ),
    ("COMMON_NAME", ("record", "taxon_names"), {"class": "genbank common name"}),
    ("GENUS_SPECIES", ("record", "taxon_names"), {"class": "scientific name"}),
    ("PHYLUM", ("record", "lineage"), {"taxon_rank": "phylum"}),
    ("CLASS", ("record", "lineage"), {"taxon_rank": "class"}),
    ("ORDER", ("record", "lineage"), {"taxon_rank": "order"}),
    ("FAMILY", ("record", "lineage"), {"taxon_rank": "family"}),
    ("TRIBE", ("record", "lineage"), {"taxon_rank": "tribe"}),
    ("GENUS", ("record", "lineage"), {"taxon_rank": "genus"}),
    ("NCBI_TAXID", ("record", "taxon_id")),
    ("BIOSAMPLE_ACCESSION", ("record", "attributes", "biosample", "value")),
    ("SAMPLE_SEX", ("record", "attributes", "sample_sex", "value")),
    ("GENOME_LENGTH", ("record", "attributes", "assembly_span", "value")),
    ("SCAFF_NUMBER", ("record", "attributes", "scaffold_count", "value")),
    ("SCAFF_N50", ("record", "attributes", "scaffold_n50", "value")),
    ("CHROMOSOME_NUMBER", ("record", "attributes", "chromosome_count", "value")),
    ("CONTIG_NUMBER", ("record", "attributes", "contig_count", "value")),
    ("CONTIG_N50", ("record", "attributes", "contig_n50", "value")),
]


def parse_args(args=None):
    Description = "Parse contents of an NCBI Assembly report and pul out meta data required by a genome note."
    Epilog = "Example usage: python parse_json_ncbi_assembly.py <FILE_IN> <FILE_OUT>"

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
    json_file = open(file_in)
    data = json.load(json_file)

    param_list = []

    if len(data["records"]) != 1:
        print_error("More than one record found")

    for f in fetch:
        attribs = None
        if len(f) == 3:
            attribs = f[2]

        param = find_element(data["records"][0], f[1], attribs, param_list, index=0)

        if param is not None:
            if f[0] == "GENOME_LENGTH":
                param = str("%.2f" % (int(param) * 1e-6))  # convert to Mbp, 2 decimal places

            if f[0] == "SCAFF_N50" or f[0] == "CONTIG_N50":
                param = str("%.1f" % (int(param) * 1e-6))  # convert to Mbp 1 decimal place

            # Convert ints and floats to str to allow for params with punctuation to be quoted
            if isinstance(param, numbers.Number):
                param = str(param)

            if any(p in string.punctuation for p in param):
                param = '"' + param + '"'

            param_list.append([f[0], param])

    if len(param_list) > 0:
        out_dir = os.path.dirname(file_out)
        make_dir(out_dir)
        with open(file_out, "w") as fout:
            fout.write(",".join(["#paramName", "paramValue"]) + "\n")
            for param_pair in param_list:
                fout.write(",".join(param_pair) + "\n")

    else:
        print_error("No parameters found!", "File: {}".format(file_in))


def find_element(data, fields, attribs, param_list, index=0):
    if type(data) == list:
        # we have a list to iterate
        if "class" in attribs.keys():
            for item in data:
                if item["class"] == attribs["class"]:
                    return item["name"]

        if "taxon_rank" in attribs.keys():
            for item in data:
                if item["taxon_rank"] == attribs["taxon_rank"]:
                    return item["scientific_name"]

        if "index" in attribs.keys():
            index = attribs["index"]
            return data[attribs["index"]]

        if "bioprojects" in attribs.keys():
            bioproject_key = None

            for param in param_list:
                if param[0] == "BIOPROJECT_ACCESSION":
                    bioproject_key = param[1]

            bioprojects = data[0]["bioprojects"]
            for project in bioprojects:
                if project["accession"] == bioproject_key:
                    if project["parent_accessions"] != None and len(project["parent_accessions"]) == 1:
                        if project["title"] != None:
                            return project["title"]

        else:
            # fields either not found or we don't yet handle parsing it
            pass

    else:
        if fields[index] in data:
            sub_data = data[fields[index]]
            if type(sub_data) == list or type(sub_data) == dict:
                return find_element(sub_data, fields, attribs, param_list, index=index + 1)
            return sub_data
        else:
            # Don't have the field so it is an error or missing
            # print(f'We could not find {fields[index]}')
            pass


def main(args=None):
    args = parse_args(args)
    parse_json(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
