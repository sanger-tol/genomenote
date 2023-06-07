#!/usr/bin/env python3

import os
import sys
import argparse
import xml.etree.ElementTree as ET

fetch = [
  ("BIOPROJECT_ACCESSION", ["PROJECT"], ("attrib", "accession")),
  ("BIOPROJECT_TITLE", ["PROJECT", "TITLE"]),
]

def parse_args(args=None):
    Description = "Parse contents of an ENA Bioproject report and pul out meta data required by a genome note."
    Epilog = "Example usage: python parse_xml_ena_bioproject.py <FILE_IN> <FILE_OUT>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_IN", help="Input XML Bioproject file.")
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
      ## Handle cases where parameter is not available for this PROJECT
      if r is None: 
        break

      if (i == max_depth):
        ## Handle more complex cases where not just fetching text for an element 
        if fn == 3:

          ## Fetch specific attribute for a given element 
          if f[2][0] == "attrib":
            try:
              param = r.attrib.get(f[2][1])
            except ValueError:
              param = None

        else: 
          try:
            param = r.text
          except ValueError:
            param = None

        if param is not None:
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
