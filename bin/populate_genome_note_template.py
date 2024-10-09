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
    parser.add_argument("--version", action="version", version="%(prog)s 1.1")
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
        locs = ["COLLECTION_LOCATION", "HIC_COLLECTION_LOCATION", "RNA_COLLECTION_LOCATION"]
        collectors = ["COLLECTORS", "HIC_COLLECTORS", "RNA_COLLECTORS"]
        inst_collectors = ["COLLECTOR_INSTITUTE", "HIC_COLLECTOR_INSTITUTE", "RNA_COLLECTOR_INSTITUTE"]
        identifiers = ["IDENTIFIER", "HIC_IDENTIFIER", "RNA_IDENTIFIER"]
        inst_identifier = ["IDENTIFIER_INSTITUTE", "HIC_IDENTIFIER_INSTITUTE", "RNA_IDENTIFIER_INSTITUTE"]

        for row in reader:
            key = row.pop(0)
            value = row[0]
            if key == "CHR_TABLE":
                value = ",".join(row)
                json_chrs = json.loads(value)
                value = json_chrs

            elif key == "ORGANISM_PART":
                value = value.lower()

            elif key in identifiers or key in inst_identifier:
                value = value.replace("|", ",")
                value = value.lower().title()
                value = value.replace("At", "at")
                value = value.replace("Of", "of")
                value = value.replace("The", "the")

            elif key in collectors or key in inst_collectors or key in locs:
                value = value.replace("|", ",")
                value = value.lower().title()
                value = value.replace("At", "at")
                value = value.replace("Of", "of")
                value = value.replace("The", "the")

            # Set URLS for BTK
            elif key == "ASSEMBLY_ACCESSION":
                # Base BTK URL
                btk_url = "https://blobtoolkit.genomehubs.org/view/GCA/dataset/GCA"
                btk_url = btk_url.replace("GCA", value)

                mydict["BTK_SNAIL_URL"] = btk_url + "/snail"
                mydict["BTK_BLOB_URL"] = btk_url + "/blob"
                mydict["BTK_CUMULATIVE_URL"] = btk_url + "/cumulative"

            mydict[key] = value

        authors = []
        seen = set()

        for i_key in (
            "IDENTIFIER",
            "HIC_IDENTIFIER",
            "RNA_IDENTIFIER",
            "COLLECTORS",
            "HIC_COLLECTORS",
            "RNA_COLLECTORS",
        ):
            item = mydict.get(i_key)
            if item:
                for i in item.split(","):
                    i = i.strip()
                    if i not in seen:
                        authors.append(i)
                        seen.add(i)

        mydict["AUTHORS"] = ", ".join(authors).strip()

        assembly_acc = mydict.get("ASSEMBLY_ACCESSION")
        if assembly_acc:
            btk_busco_url = "https://blobtoolkit.genomehubs.org/view/GCA/dataset/GCA/busco"
            btk_busco_url = btk_busco_url.replace("GCA", assembly_acc)
            mydict["BTK_BUSCO_URL"] = btk_busco_url

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
