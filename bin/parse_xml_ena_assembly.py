#!/usr/bin/env python3

import os
import sys
import argparse
import xml.etree.ElementTree as ET
import string
import numbers

fetch = [
    ("ASSEMBLY_ID", ["ASSEMBLY"], ("attrib", "alias")),
    ("BIOPROJECT_ACCESSION", ["ASSEMBLY", "STUDY_REF", "IDENTIFIERS", "PRIMARY_ID"]),
    ("ASSEMBLY_ACCESSION", ["ASSEMBLY", "IDENTIFIERS", "PRIMARY_ID"]),
    ("NCBI_TAXID", ["ASSEMBLY", "TAXON", "TAXON_ID"]),
    ("COMMON_NAME", ["ASSEMBLY", "TAXON", "COMMON_NAME"]),
    ("GENUS_SPECIES", ["ASSEMBLY", "TAXON", "SCIENTIFIC_NAME"]),
    ("PROJECT_BIOSAMPLE_ACCESSION", ["ASSEMBLY", "SAMPLE_REF", "IDENTIFIERS", "PRIMARY_ID"]),
    ("GENOME_LENGTH", ["ASSEMBLY", "ASSEMBLY_ATTRIBUTES"], ("tag", ".//*[TAG='total-length']//", "VALUE")),
    ("SCAFF_NUMBER", ["ASSEMBLY", "ASSEMBLY_ATTRIBUTES"], ("tag", ".//*[TAG='scaffold-count']//", "VALUE")),
    ("SCAFF_N50", ["ASSEMBLY", "ASSEMBLY_ATTRIBUTES"], ("tag", ".//*[TAG='n50']//", "VALUE")),
    ("GAP_COUNT", ["ASSEMBLY", "ASSEMBLY_ATTRIBUTES"], ("tag", ".//*[TAG='spanned-gaps']//", "VALUE")),
    ("CHROMOSOME_NUMBER", ["ASSEMBLY", "ASSEMBLY_ATTRIBUTES"], ("tag", ".//*[TAG='replicon-count']//", "VALUE")),
    ("CONTIG_NUMBER", ["ASSEMBLY", "ASSEMBLY_ATTRIBUTES"], ("tag", ".//*[TAG='count-contig']//", "VALUE")),
    ("CONTIG_N50", ["ASSEMBLY", "ASSEMBLY_ATTRIBUTES"], ("tag", ".//*[TAG='contig-n50']//", "VALUE")),
]


def parse_args(args=None):
    Description = "Parse contents of an ENA Assembly report and pul out meta data required by a genome note."
    Epilog = "Example usage: python parse_xml_ena_assembly.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input XML Assembly file.")
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
        param = None
        r = root
        max_depth = len(f[1])
        fn = len(f)
        i = 0

        for tag in f[1]:
            i += 1

            r = r.find(tag)
            ## Handle cases where parameter is not available for this assembly
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

                    ## Fetch paired tag-value elements from a parent, where tag is specified and value is wanted
                    if f[2][0] == "tag":
                        r = r.findall(f[2][1])
                        for child in r:
                            if child.tag == f[2][2]:
                                param = child.text

                    ## format return values
                    if param is not None:
                        if f[0] == "SPECIMEN_ID":
                            param = param.split(".")[0]
                        if f[0] == "ASSEMBLY_ID":
                            param = param.split(" ")[0]
                        if f[0] == "CHROMOSOME_NUMBER":
                            ra = root.findall("./ASSEMBLY/ASSEMBLY_ATTRIBUTES/ASSEMBLY_ATTRIBUTE")
                            for child in ra:
                                if child.find("TAG").text == "count-non-chromosome-replicon":
                                    non_chrs = child.find("VALUE").text
                                    param = str(int(param) - int(non_chrs))
                        if f[0] == "GENOME_LENGTH":
                            param = str("%.2f" % (int(param) * 1e-6))  # convert to Mbp, 2 decimal place

                        if f[0] == "SCAFF_N50" or f[0] == "CONTIG_N50":
                            param = str("%.1f" % (int(param) * 1e-6))  # convert to Mbp, 1 decimal place

                else:
                    try:
                        param = r.text
                    except ValueError:
                        param = None

        if param is not None:
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


def main(args=None):
    args = parse_args(args)
    parse_xml(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
