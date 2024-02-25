#!/usr/bin/env python3

import argparse
import os
import json
import sys
import requests
import re


NCBI_TAXONOMY_API = "https://api.ncbi.nlm.nih.gov/datasets/v1/taxonomy/taxon/%s"


def parse_args(args=None):
    Description = "Get ODB database value using NCBI API and BUSCO configuration file"

    parser = argparse.ArgumentParser(description=Description)
    parser.add_argument("NCBI_SUMMARY_JSON", help="NCBI entry for this assembly for this assembly (in JSON).")
    parser.add_argument("LINEAGE_TAX_IDS", help="Mapping between BUSCO lineages and taxon IDs.")
    parser.add_argument("FILE_OUT", help="Output CSV file.")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def get_odb(ncbi_summary, lineage_tax_ids, file_out):
    # Read the mapping between the BUSCO lineages and their taxon_id
    with open(lineage_tax_ids) as file_in:
        lineage_tax_ids_dict = {}
        for line in file_in:
            arr = line.split()
            lineage_tax_ids_dict[int(arr[0])] = arr[1]

    # Get the taxon_id of this species / assembly
    with open(ncbi_summary) as file_in:
        data = json.load(file_in)
    tax_id = data["reports"][0]["organism"]["tax_id"]

    # Using API, get the taxon_ids of all parents
    response = requests.get(NCBI_TAXONOMY_API % tax_id).json()
    ancestor_taxon_ids = response["taxonomy_nodes"][0]["taxonomy"]["lineage"]

    # Do the intersection to find the ancestors that have a BUSCO lineage
    odb_arr = [lineage_tax_ids_dict[taxon_id] for taxon_id in ancestor_taxon_ids if taxon_id in lineage_tax_ids_dict]

    # The most recent [-1] OBD10 lineage is selected
    odb_val = odb_arr[-1]
    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)

    with open(file_out, "w") as fout:
        print("busco_lineage", odb_val, sep=",", file=fout)


def main(args=None):
    args = parse_args(args)
    get_odb(args.NCBI_SUMMARY_JSON, args.LINEAGE_TAX_IDS, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
