#!/usr/bin/env python3

import os
import sys
import requests
import argparse


def parse_args(args=None):
    Description = "Query the Ensembl Metadata API to pull out annotation information required by a genome note."
    Epilog = "Example usage: python fetch_ensembl_metadata.py --taxon_id --output"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("--taxon_id", required=True, help="The species taxon id")
    parser.add_argument("--output", required=True, help="Output file path")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")

    return parser.parse_args()


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def fetch_ensembl_data(taxon, output_file):
    # Use the species taxon_id to query the Ensembl Metadata API to determine if the
    # species has been annotated. Return assmbly accesssion of annotated data and
    # a url linking to that species on the Ensembl Rapid website

    url = "https://beta.ensembl.org/data/graphql"
    variables = {"taxon": taxon}
    query = """
    query Annotation($taxon: String)
    {
        genomes(by_keyword: {species_taxonomy_id: $taxon }) {
            assembly_accession
            scientific_name
            tol_id
            dataset {
                name
                type
                dataset_type
            }
            genome_id
        }
    }
    """
    response = requests.post(url=url, json={"query": query, "variables": variables})

    if response.status_code == 200:
        param_list = []
        data = response.json()
        if data["data"]["genomes"] is not None:
            genomes = data["data"]["genomes"][0]

            if genomes["assembly_accession"]:
                accession = genomes["assembly_accession"]
                acc = f'"{accession}"'
                param_list.append(("ANNOT_ACCESSION", acc))
                species_id = genomes["genome_id"]
                annot_url = f"https://beta.ensembl.org/species/{species_id}"
                annot_url = f'"{annot_url}"'
                param_list.append(("ANNOT_URL", annot_url))

    # Write out file even if there is no annotation data to write
    out_dir = os.path.dirname(output_file)
    make_dir(out_dir)  # Create directory if it does not exist

    with open(output_file, "w") as fout:
        # Write header
        fout.write(",".join(["#paramName", "paramValue"]) + "\n")

        for param_pair in param_list:
            fout.write(",".join(param_pair) + "\n")

    return output_file


def main(args=None):
    args = parse_args(args)
    fetch_ensembl_data(args.taxon_id, args.output)


if __name__ == "__main__":
    sys.exit(main())
