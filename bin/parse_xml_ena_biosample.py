#!/usr/bin/env python3

import os
import sys
import argparse
import xml.etree.ElementTree as ET
import string
import numbers

fetch = [
    ("GAL", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='GAL']//", "VALUE")),
    ("SPECIMEN_ID", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='specimen id']//", "VALUE")),
    ("COLLECTORS", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='collected by']//", "VALUE")),
    ("COLLECTOR_INSTITUTE", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='collecting institution']//", "VALUE")),
    (
        "COLLECTION_LOCATION",
        ["SAMPLE", "SAMPLE_ATTRIBUTES"],
        ("tag", ".//*[TAG='geographic location (region and locality)']//", "VALUE"),
    ),
    ("IDENTIFIER", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='identified by']//", "VALUE")),
    ("IDENTIFIER_INSTITUTE", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='identifier_affiliation']//", "VALUE")),
    ("COMMON_NAME", ["SAMPLE", "SAMPLE_NAME", "COMMON_NAME"]),
    ("GENUS_SPECIES", ["SAMPLE", "SAMPLE_NAME", "SCIENTIFIC_NAME"]),
    ("NCBI_TAXID", ["SAMPLE", "SAMPLE_NAME", "TAXON_ID"]),
    ("SAMPLE_SEX", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='sex']//", "VALUE")),
    (
        "COLLECTION_LOCATION",
        ["SAMPLE", "SAMPLE_ATTRIBUTES"],
        ("tag", ".//*[TAG='geographic location (region and locality)']//", "VALUE"),
    ),
    (
        "COLLECTION_DATE",
        ["SAMPLE", "SAMPLE_ATTRIBUTES"],
        ("tag", ".//*[TAG='collection date']//", "VALUE"),
    ),
    ("LATITUDE", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='geographic location (latitude)']//", "VALUE")),
    ("LONGITUDE", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='geographic location (longitude)']//", "VALUE")),
    ("HABITAT", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='habitat']//", "VALUE")),
    ("BIOSAMPLE_ACCESSION", ["SAMPLE"], ("attrib", "accession")),
    ("ORGANISM_PART", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='organism part']//", "VALUE")),
    ("TOLID", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='tolid']//", "VALUE")),
]


def parse_args(args=None):
    Description = "Parse contents of an ENA SAMPLE report and pull out meta data required by a genome note."
    Epilog = "Example usage: python parse_xml_ena_sample.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input XML SAMPLE file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check xml file -> {}".format(error)
    if context != "":
        if context_str != "":
            error_str = "ERROR: Please check xml file -> {}\n{}: '{}'".format(
                error, context.strip(), context_str.strip()
            )
        else:
            error_str = "ERROR: Please check xml file -> {}\n{}".format(error, context.strip())

    print(error_str)
    sys.exit(1)


def parse_xml(file_in, file_out):
    tree = ET.parse(file_in)
    root = tree.getroot()
    param_list = []

    # Extract biosample type from FILE_OUT
    biosample_type = None
    if "HIC" in file_out.upper():
        biosample_type = "HIC"
    elif "RNA" in file_out.upper():
        biosample_type = "RNA"

    for f in fetch:
        param = None
        r = root
        max_depth = len(f[1])
        fn = len(f)
        i = 0

        for tag in f[1]:
            i += 1

            r = r.find(tag)
            ## Handle cases where parameter is not available for this SAMPLE
            if r is None:
                break

            if i == max_depth:
                ## Handle more complex cases where not just fetching text for an element
                if fn == 3:
                    ## Fetch specific attribute for a given element
                    if f[2][0] == "attrib":
                        try:
                            param = r.attrib.get(f[2][1])
                        except ValueError:
                            param = None
                    ## Count child elements with specific tag
                    if f[2][0] == "count":
                        if r is not None:
                            param = str(len(r.findall(f[2][1]))) if len(r.findall(f[2][1])) != 0 else None
                        else:
                            param = None

                    ## Fetch paired tag-value elements from a parent, where tag is specified and value is wanted
                    if f[2][0] == "tag":
                        r = r.findall(f[2][1])
                        for child in r:
                            if child.tag == f[2][2]:
                                param = child.text

                else:
                    try:
                        param = r.text
                    except ValueError:
                        param = None

                if param is not None:
                    # Preprocess some values to standardise their format
                    if f[0] == "GAL":
                        param = param.title()

                    # pre-process collection location
                    if f[0] == "COLLECTION_LOCATION":
                        location_list = param.split(" | ")
                        location_list.reverse()

                        # remove United Kingdom from location
                        if "UNITED KINGDOM" in location_list:
                            location_list.remove("UNITED KINGDOM")
                        elif "United Kingdom" in location_list:
                            location_list.remove("United Kingdom")

                        param = ", ".join(location_list).title()

                    # organism part should be in lower case
                    if f[0] == "ORGANISM_PART":
                        param = param.lower()

                    # Convert ints and floats to str to allow for params with punctuation to be quoted
                    if isinstance(param, numbers.Number):
                        param = str(param)

                    if any(p in string.punctuation for p in param):
                        param = '"' + param + '"'
                    # Prefix parameter name if biosample type is HiC or RNA
                    param_name = f[0]
                    if biosample_type in ["HIC", "RNA"]:
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


def main(args=None):
    args = parse_args(args)
    parse_xml(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
