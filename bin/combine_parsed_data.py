#!/usr/bin/env python3

import os
import sys
import argparse


def parse_args(args=None):
    Description = "Combined the parsed data files from each of the genome meta data sources."
    Epilog = "Example usage: python parse_xml_ena_bioproject.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("--ena_assembly_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--ena_bioproject_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--ena_biosample_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--ena_taxonomy_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--ncbi_assembly_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--ncbi_taxonomy_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--goat_assembly_file", help="Input parsed ENA assembly file.", required=False)
    parser.add_argument("--out", help="Output file.", required=True)
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def main(args=None):
    args = parse_args(args)


if __name__ == "__main__":
    sys.exit(main())
