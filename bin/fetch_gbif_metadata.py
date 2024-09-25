#!/usr/bin/env python3

import requests
import json
import argparse
import sys


def parse_args(args=None):
    Description = "Parse contents of an ENA Taxonomy report and pul out meta data required by a genome note."
    Epilog = "Example usage: python fetch_gbif_metadata.py --genus --species --output"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("--genus", required=True, help="The genus of the species")
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
                authorship = species_data.get("authorship")  # Retrieve authorship field

                # Initialize param_list
                param_list = []

                if len(param_list) > 0:
                    out_dir = os.path.dirname(output_file)
                    make_dir(out_dir)  # Create directory if it does not exist

                    with open(output_file, "w") as fout:
                        # Write header
                        fout.write(",".join(["#paramName", "paramValue"]) + "\n")
                        for param_pair in param_list:
                            fout.write(",".join(param_pair) + "\n")
                        if authorship:
                            key = "TAXONOMY_AUTHORITY"
                            value = authorship
                            fout.write(f'{key},"{value}"\n')
                            return output_file

    return "Authorship not found."


def main(args=None):
    args = parse_args(args)
    fetch_gbif_data(args.genus, args.species, args.output)


if __name__ == "__main__":
    sys.exit(main())
