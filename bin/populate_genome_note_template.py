#!/usr/bin/env python3

import os
import sys
import argparse
import csv
import jinja2
import json
from docxtpl import DocxTemplate


def parse_args(args=None):
    Description = ""
    Epilog = ""

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("PARAM_FILE", help="Input parameters CSV file.")
    parser.add_argument("TEMPLATE_FILE", help="Input Genome Note Template file.")
    parser.add_argument("TEMPLATE_TYPE", help="Input Genome Note Template file type.")
    parser.add_argument("FILE_OUT", help="Output file.")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def write_file(template, type, file_out):
    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)
    if type == "docx":
        template.save(os.path.join(out_dir, file_out))
    else:
        with open(file_out, "w") as fout:
            fout.write(template)


def build_param_list(param_file):
    with open(param_file, "r") as infile:
        reader = csv.reader(infile)

        mydict = {}
        for row in reader:
            key = row.pop(0)
            value = row[0]
            if key == "CHR_TABLE":
                value = ",".join(row)
                json_chrs = json.loads(value)
                value = json_chrs

            if key == "TISSUE_TYPE":
                value = value.lower()

            if key == "IDENTIFIER" or key == "IDENTIFIER_INSTITUTE":
                value = value.replace("|", ",")
                value = value.lower().title()

            if key == "COLLECTORS" or key == "COLLECTOR_INSTITUTE" or key == "COLLECTION_LOCATION":
                value = value.replace("|", ",")
                value = value.lower().title()
                value = value.replace("At", "at")
                value = value.replace("Of", "of")
                value = value.replace("The", "the")

            mydict[key] = value

        authors = []
        seen = set()
        if mydict["IDENTIFIER"]:
            for i in mydict["IDENTIFIER"].split(", "):
                i = i.rstrip()
                if i not in seen:
                    authors.append(i)
                    seen.add(i)

        if mydict["COLLECTORS"]:
            for c in mydict["COLLECTORS"].split(", "):
                c = c.rstrip()
                if c not in seen:
                    authors.append(c)
                    seen.add(c)

        mydict["AUTHORS"] = ", ".join(authors)

        return mydict


def populate_template(param_file, template_file, template_type, file_out):
    myenv = jinja2.Environment(undefined=jinja2.DebugUndefined)
    context = build_param_list(param_file)
    if template_type == "docx":
        template = DocxTemplate(template_file)
        template.render(context, myenv)
        write_file(template, template_type, file_out)
    else:
        with open(template_file, "r") as file:
            data = file.read()

        template = myenv.from_string(data)
        content = template.render(context)
        write_file(content, template_type, file_out)


def main(args=None):
    args = parse_args(args)
    populate_template(args.PARAM_FILE, args.TEMPLATE_FILE, args.TEMPLATE_TYPE, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
