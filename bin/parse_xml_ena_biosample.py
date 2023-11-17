#!/usr/bin/env python3

import os
import sys
import argparse
import xml.etree.ElementTree as ET

fetch = [
    ("GAL", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='GAL']//", "VALUE")),
    ("COLLECTORS", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='collected by']//", "VALUE")),
    ("COLLECTOR_INSTITUTE", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='collecting institution']//", "VALUE")),
    (
        "COLLECTOR_PLACE",
        ["SAMPLE", "SAMPLE_ATTRIBUTES"],
        ("tag", ".//*[TAG='geographic location (region and locality)']//", "VALUE"),
    ),
    (
        "COLLECTOR_COUNTRY",
        ["SAMPLE", "SAMPLE_ATTRIBUTES"],
        ("tag", ".//*[TAG='geographic location (country and/or sea)']//", "VALUE"),
    ),
    ("IDENTIFIER", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='identified by']//", "VALUE")),
    ("IDENTIFIER_INSTITUTE", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='identifier_affiliation']//", "VALUE")),
    ("COMMON_NAME", ["SAMPLE", "SAMPLE_NAME", "COMMON_NAME"]),
    ("GENUS_SPECIES", ["SAMPLE", "SAMPLE_NAME", "SCIENTIFIC_NAME"]),
    ("NCBI_TAXID", ["SAMPLE", "SAMPLE_NAME", "TAXON_ID"]),
    ("SAMPLE_SEX", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='sex']//", "VALUE")),
    (
        "COLLECTOR_LOCATION",
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
    ("TISSUE_TYPE", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='organism part']//", "VALUE")),
    ("TOL_ID", ["SAMPLE", "SAMPLE_ATTRIBUTES"], ("tag", ".//*[TAG='tolid']//", "VALUE")),
]


def parse_args(args=None):
    Description = "Parse contents of an ENA SAMPLE report and pul out meta data required by a genome note."
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

    for f in fetch:
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

                    ## Count child elements with specfic tag
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


def main(args=None):
    args = parse_args(args)
    parse_xml(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
