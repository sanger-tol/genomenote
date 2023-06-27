#!/usr/bin/env python3

import os
import sys
import argparse
import csv
from docxtpl import DocxTemplate


def parse_args(args=None):
    Description = ""
    Epilog = ""

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("PARAM_FILE", help="Input parameters CSV file.")
    parser.add_argument("TEMPLATE_FILE", help="Input Genome Note Template Doc file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def write_file(template, file_out):
    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)
    template.save(os.path.join(out_dir, file_out))

def build_param_list(param_file):
    with open(param_file, 'r') as infile:
        reader = csv.reader(infile)
        mydict = {rows[0]:rows[1] for rows in reader}
        return mydict

def populate_template(param_file, template_file, file_out):
    context = build_param_list(param_file)
    template = DocxTemplate(template_file)
    template.render(context)
    write_file(template, file_out)

def main(args=None):
    args = parse_args(args)
    populate_template(args.PARAM_FILE, args.TEMPLATE_FILE, args.FILE_OUT)

if __name__ == "__main__":
    sys.exit(main())
