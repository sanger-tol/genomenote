#!/usr/bin/env python3

import argparse
import json
import sys


def parse_args(args=None):
    Description = "Verify the integrity of a JSON file coming from NCBI datasets"

    parser = argparse.ArgumentParser(description=Description)
    parser.add_argument("NCBI_SUMMARY_JSON", help="NCBI entry for this assembly (in JSON).")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def check_json(ncbi_summary):
    with open(ncbi_summary) as file_in:
        data = json.load(file_in)

    assert "reports" in data


def main(args=None):
    args = parse_args(args)
    check_json(args.NCBI_SUMMARY_JSON)


if __name__ == "__main__":
    sys.exit(main())
