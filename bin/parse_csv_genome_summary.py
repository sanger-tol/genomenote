#!/usr/bin/env python3

import argparse
import os
import csv
import json
import sys
import string
import numbers

param_lookup = {
    "Accession": "ASSEMBLY_ACCESSION",
    "Organism_Name": "GENUS_SPECIES",
    "ToL_ID": "TOLID",
    "Taxon_ID": "NCBI_TAXID",
    "Assembly_Name": "ASSEMBLY_ID",
    "Life_Stage": "LIFESTAGE",
    "Tissue": "TISSUE_TYPE",
    "Sex": "SAMPLE_SEX",
    "Total_Sequence": "GENOME_LENGTH",
    "Chromosomes": "CHROMOSOME_NUMBER",
    "Scaffolds": "SCAFF_NUMBER",
    "Scaffold_N50": "SCAFF_N50",
    "Contigs": "CONTIG_NUMBER",
    "Contig_N50": "CONTIG_N50",
    "Mitochondrion": "MITO_SIZE",
    "##BUSCO": "BUSCO_REF",
    "Summary": "BUSCO_STRING",
    "QV": "QV",
    "Completeness": "KMER",
}


def parse_args(args=None):
    Description = "Parse contents of the Genome Summary CSV file produced by the Genome Statistics subworkflow and pul out meta data required by a genome note."
    Epilog = "Example usage: python parse_json_ncbi_assembly.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input CSV Genome Summary file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check csv file -> {}".format(error)
    if context != "":
        if context_str != "":
            error_str = "ERROR: Please check csv file -> {}\n{}: '{}'".format(
                error, context.strip(), context_str.strip()
            )
        else:
            error_str = "ERROR: Please check csv file -> {}\n{}".format(error, context.strip())

    print(error_str)
    sys.exit(1)


def parse_csv(file_in, file_out):
    param_list = []
    with open(file_in) as csvfile:
        reader = csv.reader(csvfile)

        for row in reader:
            if row[0] in param_lookup:
                key = param_lookup.get(row[0])
                param = row[1]

                if key == "BUSCO_STRING":
                    param = '"' + param + '"'
                    busco = param.replace("[", ":").split(":")
                    param_list.append(["BUSCO", busco[1]])

                if key == "GENOME_LENGTH":
                    param = str(round((int(param) * 1e-6), 2))  # convert to Mbp, 2 decimal places
                
                if key == "SCAFF_N50" or key == "CONTIG_N50":
                    param = str(round((int(param) * 1e-6), 1))  # convert to Mbp, 1 decimal place

                # Convert ints and floats to str to allow for params with punctuation to be quoted
                if isinstance(param, numbers.Number):
                    param = str(param)

                if any(p in string.punctuation for p in param):
                    param = '"' + param + '"'

                if len(param) != 0:
                    param_list.append([key, param])

            elif row[0] == "##Chromosome":
                chrs = []
                chr_list_complete = 0

                while chr_list_complete < 1:
                    chr_row = reader.__next__()

                    if chr_row[0].startswith("##"):
                        chr_list_complete = 1
                        sorted_chrs = sorted(chrs, key=lambda d: d["Length"], reverse=True)
                        param_list.append(["LONGEST_SCAFF", sorted_chrs[0].get("Length")])
                        json_chrs = json.dumps(chrs)
                        param_list.append(["CHR_TABLE", json_chrs])

                    else:
                        chrs.append(
                            {"Chromosome": chr_row[0], "Length": chr_row[1], "GC": chr_row[2], "Accession": chr_row[3]}
                        )

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
    parse_csv(args.FILE_IN, args.FILE_OUT)


if __name__ == "__main__":
    sys.exit(main())
