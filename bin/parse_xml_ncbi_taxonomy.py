#!/usr/bin/env python3

import os
import sys
import argparse
import xml.etree.ElementTree as ET

fetch = [
  ("COMMON_NAME", ["Taxon", "OtherNames", "GenbankCommonName"]),
  ("GENUS_SPECIES",["Taxon", "Scientific_Name"]),
  ("NCBI_TAXID", ["Taxon", "TaxId"]),
  ("TAXONOMY_AUTHORITY", ["Taxon", "OtherNames"], ("Name", "ClassCDE", "authority", "DispName")),
  ("TAX_STRING", ["Taxon", "Lineage"]),
  ("KINGDOM", ["Taxon", "LineageEx"], ("Taxon", "Rank", "kingdom", "ScientificName")), 
  ("PHYLUM", ["Taxon", "LineageEx"], ("Taxon", "Rank", "phylum", "ScientificName")),
  ("CLASS", ["Taxon", "LineageEx"], ("Taxon", "Rank", "class", "ScientificName")),
  ("ORDER", ["Taxon", "LineageEx"], ("Taxon", "Rank", "order", "ScientificName")), 
  ("FAMILY", ["Taxon", "LineageEx"], ("Taxon", "Rank", "family", "ScientificName")), 
  ("TRIBE", ["Taxon", "LineageEx"], ("Taxon", "Rank", "tribe", "ScientificName")), 
  ("GENUS", ["Taxon", "LineageEx"], ("Taxon", "Rank", "genus", "ScientificName")) 
]



def parse_args(args=None):
    Description = "Parse contents of a NCBI taxonomy report and pul out meta data required by a genome note."
    Epilog = "Example usage: python parse_xml_ncbi_taxonomy.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input XML Assembly file.")
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

  for f in fetch:
      r = root
      max_depth = len(f[1])
      fn = len(f)
      i = 0

      for tag in f[1]: 
        i+=1

        r =  r.find(tag)
        ## Handle cases where parameter is not available for this assembly
        if r is None: 
          break

        if (i == max_depth):
          ## Handle more complex cases where not just fetching text for an element 
          if fn == 3:

            ## Fetch rank and scientific name from a parent taxon, where rank is specified and specified and scientific_name is wanted
            if f[2][0] == "Taxon":
              rank_found = 0
              r = r.findall(f[2][0])
              for child in r:
                c =  child.find(f[2][1])
                if c.text == f[2][2]:
                  rank_found = 1
                  name = child.find(f[2][3])
                  if name is not None:
                    param = name.text                    
                  else:
                    param = None

              if rank_found == 0:
                param = None

            ## Fetch authority(ies) 
            if f[2][0] == "Name":
              authority_found = 0
              r = r.findall(f[2][0])
              for child in r:
                c =  child.find(f[2][1])
                if c.text == f[2][2]:
                  authority_found = 1
                  name = child.find(f[2][3])
                  if name is not None:
                    param = '"' + name.text + '"'                    
                  else:
                    param = None

              if authority_found == 0:
                param = None

          else: 
            try:
              param = r.text
            except ValueError:
              param = None


          if param is not None:
            ## format return values 
            if f[0] == "TAX_STRING":
              param = '"' + param  + '"'

            param_list.append([f[0], param])


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