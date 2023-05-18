#!/usr/bin/env python3

import os
import sys
import argparse
import xml.etree.ElementTree as ET

fetch = {
  "kingdom": ["KINGDOM"],
  "phylum": ["PHYLUM"],
  "class": ["CLASS"],
  "order": ["ORDER"],
  "family": ["FAMILY"],
  "tribe": ["TRIBE"],
  "genus": ["GENUS"], 
}

def parse_args(args=None):
    Description = "Parse contents of an ENA Taxonomy report and pul out meta data required by a genome note."
    Epilog = "Example usage: python parse_xml_ena_taxonomy.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input XML Taxonomy file.")
    parser.add_argument("FILE_OUT", help="Output file.")
    parser.add_argument('--version', action='version', version='%(prog)s 1.0')
    return parser.parse_args(args)


def make_dir(path):
  if len(path) > 0:
    os.makedirs(path, exist_ok=True)


def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check xml file -> {}".format(error)
    if context != "":
      if context_str != "":
        error_str = "ERROR: Please check xml file -> {}\n{}: '{}'".format(
            error, context.strip(), context_str.strip()
        )
      else: 
        error_str = "ERROR: Please check xml file -> {}\n{}".format(
            error, context.strip()
        )

    print(error_str)
    sys.exit(1)    

def parse_xml(file_in, file_out):

  tree = ET.parse(file_in)
  root = tree.getroot()
  param_list = []

  taxon = root.find("taxon")
  common_name = taxon.get("commonName")
  scientific_name = taxon.get("scientificName")
  taxon_id = taxon.get("taxId")
  
  if common_name is not None:
    param_list.append(["COMMON_NAME", common_name ])
  if scientific_name is not None:  
    param_list.append(["GENUS_SPECIES", scientific_name ])

  tax_string = []
  lineage = root.find('taxon/lineage')
  for child in lineage: 
    name = child.get("scientificName")
    if name is not None and name != "root":
      tax_string.append(name)  
    
    rank = child.get("rank")
    if rank is not None:
      if rank in fetch:
        if name is not None:
          fetch[rank].append(name)

  for f in fetch:
    if len(fetch[f]) > 1:
      param_list.append([fetch[f][0], fetch[f][1]])

  if taxon_id is not None:
    param_list.append(["NCBI_TAXID", taxon_id ])

  tax_string.reverse()
  full_taxonomy = ",".join(tax_string)

  param_list.append(["TAX_STRING", '"' + full_taxonomy +'"'])

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
    args=parse_args(args)
    parse_xml(args.FILE_IN, args.FILE_OUT)

if __name__ == "__main__":
    sys.exit(main())