#!/usr/bin/env python3

import os
import sys
import requests
import argparse


def parse_args(args=None):
    Description = "Use the genome assembly accession to fetch additional infromation on genome from ENA"
    Epilog = "Example usage: python check_parameters.py --assembly --wgs_biosample --output"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("--assembly", required=True, help="The INSDC accession for the assembly")
    parser.add_argument("--wgs_biosample", required=True, help="The biosample accession for the WGS data")
    parser.add_argument("--hic_biosample", required=False, help="The biosample accession for the Hi-C data")
    parser.add_argument("--rna_biosample", required=False, help="The biosample accession for the RNASeq data")
    parser.add_argument("--output", required=True, help="Output file path")
    return parser.parse_args()


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def fetch_assembly_data(assembly, wgs_biosample, hic_biosample, rna_biosample, output_file):
    url = f"https://www.ebi.ac.uk/ena/portal/api/search?query=assembly_set_accession%3D%22{assembly}%22&result=assembly&fields=assembly_set_accession%2Ctax_id%2Cscientific_name%2Cstudy_accession&limit=0&download=true&format=json"
    response = requests.get(url)

    if response.status_code == 200:
        assembly_data = response.json()
        taxon_id = assembly_data[0].get("tax_id", None)
        species = assembly_data[0].get("scientific_name", None).replace(" ", "_")
        study = assembly_data[0].get("study_accession", None)
        params = [assembly, species, taxon_id]
        header = ["assembly", "species", "taxon_id"]

        if study:
            study_url = f"https://www.ebi.ac.uk/ena/portal/api/search?query=study_accession%3D%22{study}%22&result=study&fields=parent_study_accession&limit=0&download=true&format=json"
            study_response = requests.get(study_url)

            if study_response.status_code == 200:
                study_data = study_response.json()
                studies = study_data[0].get("parent_study_accession").split(";")
                params.append(studies[0])
                header.append("bioproject")

            else:
                raise AssertionError(f"Could not determine the Bioproject linked to this assembly {assembly}\n")
        else:
            raise AssertionError(f"Could not determine the Bioproject linked to this assembly {assembly}\n")

        # Validate wgs_biosample
        wgs_url = f"https://www.ebi.ac.uk/ena/portal/api/search?query=sample_accession%3D%22{wgs_biosample}%22&result=sample&fields=sample_accession%2Ctax_id&limit=0&download=true&format=json"
        wgs_response = requests.get(wgs_url)

        if wgs_response.status_code == 200:
            wgs_data = wgs_response.json()
            tax_id = wgs_data[0].get("tax_id")

            if tax_id != taxon_id:
                raise AssertionError(
                    f"The WGS biosample taxon id: {tax_id} does not match the assembly taxon id: {taxon_id}\n"
                )
            else:
                params.append(wgs_biosample)
                header.append("wgs_biosample")

        else:
            raise AssertionError(f"The WGS biosample id: {wgs_biosample} could not retrieved from ENA\n")

        # Validate hic_biosample
        if hic_biosample and hic_biosample != "null":
            print(hic_biosample)
            hic_url = f"https://www.ebi.ac.uk/ena/portal/api/search?query=sample_accession%3D%22{hic_biosample}%22&result=sample&fields=sample_accession%2Ctax_id&limit=0&download=true&format=json"
            hic_response = requests.get(hic_url)

            if hic_response.status_code == 200:
                hic_data = hic_response.json()
                hic_tax_id = hic_data[0].get("tax_id")

                if hic_tax_id != taxon_id:
                    raise AssertionError(
                        f"The Hi-C biosample taxon id: {hic_tax_id} does not match the assembly taxon id: {taxon_id}\n"
                    )
                else:
                    header.append("hic_biosample")
                    params.append(hic_biosample)

            else:
                raise AssertionError(f"The Hi-C biosample id: {hic_biosample} could not retrieved from ENA\n")
        else:
            header.append("hic_biosample")
            params.append("null")

        # Validate rna_biosample
        if rna_biosample and rna_biosample != "null":
            rna_url = f"https://www.ebi.ac.uk/ena/portal/api/search?query=sample_accession%3D%22{rna_biosample}%22&result=sample&fields=sample_accession%2Ctax_id&limit=0&download=true&format=json"
            rna_response = requests.get(rna_url)

            if rna_response.status_code == 200:
                rna_data = rna_response.json()
                rna_tax_id = rna_data[0].get("tax_id")

                if rna_tax_id != taxon_id:
                    raise AssertionError(
                        f"The RNASeq biosample taxon id: {rna_tax_id} does not match the assembly taxon id: {taxon_id}\n"
                    )
                else:
                    header.append("rna_biosample")
                    params.append(rna_biosample)

            else:
                raise AssertionError(f"The RNASeq biosample id: {rna_biosample} could not retrieved from ENA\n")

        else:
            header.append("rna_biosample")
            params.append("null")

        with open(output_file, "w") as fout:
            # Write header
            fout.write(",".join(header) + "\n")
            fout.write(",".join(params) + "\n")

            return output_file
    else:
        raise AssertionError(f"The assemby accession: {assembly} was not found\n")


def main(args=None):
    args = parse_args(args)
    hic_biosample = args.hic_biosample
    rna_biosample = args.rna_biosample
    fetch_assembly_data(
        args.assembly,
        args.wgs_biosample,
        hic_biosample,
        rna_biosample,
        args.output,
    )


if __name__ == "__main__":
    sys.exit(main())
