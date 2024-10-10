#!/usr/bin/env python3

import os
import sys
import requests
import argparse


def parse_args(args=None):
    Description = "Parse contents of an ENA Taxonomy report and pull out metadata required by a genome note."
    Epilog = "Example usage: python fetch_gbif_metadata.py --genus --species --output"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("--species", required=True, help="The species name")
    parser.add_argument("--output", required=True, help="Output file path")
    return parser.parse_args()


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def fetch_gbif_data(genus, species, output_file):
    match_url = f"https://api.gbif.org/v1/species/match?verbose=true&genus={genus}&species={species}"
    response = requests.get(match_url)

    if response.status_code == 200:
        match_data = response.json()
        usage_key = match_data.get("usageKey")

        if usage_key:
            species_url = f"https://api.gbif.org/v1/species/{usage_key}"
            species_response = requests.get(species_url)

            if species_response.status_code == 200:
                species_data = species_response.json()

                # Metadata fields to extract
                metadata_fields = {
                    "PHYLUM": "phylum",
                    "CLASS": "class",
                    "ORDER": "order",
                    "FAMILY": "family",
                    "GENUS": "genus",
                    "SPECIES": "species",
                    "GENUS_SPECIES": "canonicalName",
                    "COMMON_NAME": "vernacularName",
                    "TAXONOMY_AUTHORITY": "authorship",
                }

                param_list = []

                # Retrieve the required fields and create parameter pairs
                for key, json_key in metadata_fields.items():
                    value = species_data.get(json_key)
                    if value:
                        # Special handling for TAXONOMY_AUTHORITY to clean up the value
                        if key == "TAXONOMY_AUTHORITY":
                            value = value.strip()
                            # Wrap the authorship in quotes
                            value = f'"{value}"'  # Enclose the value in quotes

                        param_list.append((key, value))

                # Check if there is any data to write
                if len(param_list) > 0:
                    out_dir = os.path.dirname(output_file)
                    make_dir(out_dir)  # Create directory if it does not exist

                    with open(output_file, "w") as fout:
                        # Write header
                        fout.write(",".join(["#paramName", "paramValue"]) + "\n")
                        for param_pair in param_list:
                            fout.write(",".join(param_pair) + "\n")

                    return output_file

    return "Metadata not found."


def main(args=None):
    args = parse_args(args)
    (genus, species) = args.species.split("_")
    fetch_gbif_data(genus, species, args.output)


if __name__ == "__main__":
    sys.exit(main())
