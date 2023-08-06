#!/usr/bin/env python3

import sys
import argparse
import csv
from tol.api_client import ApiDataSource, ApiObject
from tol.core import DataSourceFilter


def parse_args(args=None):
    Description = ""
    Epilog = ""

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("PARAM_FILE", help="Input parameters CSV file.")
    parser.add_argument("TOL_API_URL", help="URL for Genome Notes API")
    parser.add_argument("TOL_API_KEY", help="Key for using ToL API Client")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def print_error(error, context="Line", context_str=""):
    error_str = "ERROR: Please check file -> {}".format(error)
    if context != "":
        if context_str != "":
            error_str = "ERROR: Please check file -> {}\n{}: '{}'".format(
                error, context.strip(), context_str.strip()
            )
        else:
            error_str = "ERROR: Please check file -> {}\n{}".format(error, context.strip())

    print(error_str)
    sys.exit(1)

def build_param_list(param_file):
    with open(param_file, "r") as infile:
        reader = csv.reader(infile)
        mydict = {rows[0]: rows[1] for rows in reader}
        return mydict


def fetch_ads(url, key):
    ads = ApiDataSource(
        {
            #"url": "https://notes-staging.tol.sanger.ac.uk/api/v1",
            "url": url,    
            "key": key
        }
    )
    return ads


def write_to_db(param_file, url, key):
    params = build_param_list(param_file)
    ads = fetch_ads(url, key)

    assembly_accession = params.get("ASSEMBLY_ACCESSION") if params.get("ASSEMBLY_ACCESSION") else None
    species_name = params.get("GENUS_SPECIES") if params.get("GENUS_SPECIES") else None

    # Check species exists, and add if missing
    if species_name:
        species_exists = ads.get_list('species', DataSourceFilter(exact = {
            "scientific_name": species_name
        }))

        if len(list(species_exists)) != 0:
            species = species_exists[0]
        else:
            species = ApiObject('species', None,
                                attributes={
                                    "scientific_name": params.get("GENUS_SPECIES")
                                })
            
            species = ads.create(species)
    else:
        print_error("No GENUS_SPECIES found!", "File: {}".format(param_file))

    # check the template has been defined, add if not and fetch value
    template_exists = ads.get_list('template', DataSourceFilter(exact = {
        "name": "WOR_Standard", 
        "journal": "Wellcome Open Research"
    }))

    if len(list(template_exists)) != 0:
        template = template_exists[0]
    else:
        template = ApiObject('template', None,
                             attributes={
                                 "name": "WOR_Standard",
                                 "journal": "Wellcome Open Research",
                                 "template_body": ""
                             })
            
        template = ads.create(template)


    if assembly_accession: 
        filter = DataSourceFilter(exact = {"accession": assembly_accession })
        assembly_exists = ads.get_list('assembly', object_filters=filter)

        # retrieve assembly info from database or add if not already there    
        if len(list(assembly_exists)) != 0:    
            assembly = assembly_exists[0]
        else:
            assembly_name = params.get("SPECIMEN_ID") if params.get("SPECIMEN_ID") else None
            taxon_id = params.get("NCBI_TAXID") if params.get("NCBI_TAXID") else None

            assembly = ApiObject('assembly', None,
                                 attributes={
                                     "accession": assembly_accession,
                                     "name": assembly_name,
                                     "taxon_id": taxon_id
                                 })


            assembly = ads.create(assembly)  


        for parameter in params:
            if parameter == "#paramName":
                continue
            
            parameter_value = params.get(parameter)

            parameter_class_exists = ads.get_list('parameter_classes',  DataSourceFilter(exact = {
                "name": parameter,
                "jats": parameter
            }))

            if len(list(parameter_class_exists)) != 0:
                parameter_class = parameter_class_exists[0]
            else:  
                parameter_class = ApiObject('parameter_classes', None,
                                                   attributes={
                                                        "name": parameter,
                                                        "jats": parameter
                                                   })

                parameter_class = ads.create(parameter_class)
            

            parameter_exists = ads.get_list('parameters', DataSourceFilter(exact = {
                "parameter_class_id": parameter_class.id,
                "value": parameter_value,
                "assembly_accession": assembly.accession
            }))

            if len(list(parameter_exists)) != 0:
                parameters = parameter_exists[0]
                parameters.value = parameter_value
                ads.update(parameters)

            else:
                parameters = ApiObject('parameters', None,
                                      attributes={
                                          "value": parameter_value,
                                          "assembly_accession": assembly_accession
                                      },
                                      relationships={
                                          "parameter_classes": parameter_class
                                      }) 
                
                parameters = ads.create(parameters)

            template_parameter_exists = ads.get_list('template_parameters', DataSourceFilter(exact = {
                "template_id": template.id,
                "parameter_id": parameters.id,
            }))

            if len(list(template_parameter_exists)) != 0:
                template_parameter = template_parameter_exists[0]

            else:
                template_parameter = ApiObject('template_parameters', None,
                                               attributes={
                                                   "required": True
                                               },
                                               relationships={
                                                   "template": template,
                                                   "parameters": parameters
                                               })
                
                template_parameter = ads.create(template_parameter)



def main(args=None):
    args = parse_args(args)
    write_to_db(args.PARAM_FILE, args.TOL_API_URL, args.TOL_API_KEY)

if __name__ == "__main__":
    sys.exit(main())
