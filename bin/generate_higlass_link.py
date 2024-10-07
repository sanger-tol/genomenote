#!/usr/bin/env python3

import os
import sys
import argparse
import csv
import requests


def parse_args(args=None):
    Description = "Parse contents of an ENA Assembly report and pul out meta data required by a genome note."
    Epilog = "Example usage: python generate_higlass_link.py <FILE_NAME> <MAP_UUID> <GRID_UUID> <GENOME_FILE>"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument("FILE_NAME", help="Prefix file name for the project.")
    parser.add_argument("MAP_UUID", help="UUID for the .mcool file tileset.")
    parser.add_argument("GRID_UUID", help="UUID for the .genome file tileset.")
    parser.add_argument("HIGLASS_SERVER", help="Higlass server url")
    parser.add_argument("GENOME_FILE", help="Input .genome file")
    parser.add_argument("OUTPUT_FILE", help="Output .csv file")
    parser.add_argument("--version", action="version", version="%(prog)s 1.0")
    return parser.parse_args(args)


def calculate_genome_size(file_in):
    # calculate total genome length by adding all contig/scaffold lengths in the .genome file
    genome_length = 0
    with open(file_in) as csvfile:
        reader = csv.reader(csvfile, delimiter="\t")
        for row in reader:
            genome_length += int(row[1])

    return genome_length


def check_viewconfig_exists(higlass_server, file_name):
    # Use HiGlass API to see if a viewconfig matching the file_name already exists on the server
    headers = {"Content-Type": "application/json"}
    params = {"d": file_name}
    response = requests.get(f"{higlass_server}/api/v1/viewconfs/l/", params=params, headers=headers)
    if response:
        return True
    return False


def request_viewconfig(higlass_server, file_name, map_uuid, grid_uuid, genome_length):
    # define viewconfig, "contents" array should contain a section for each filetype.
    # uid of viewconfig should match the file_name
    request_data = {
        "uid": file_name,
        "viewconf": {
            "editable": True,
            "zoomFixed": False,
            "trackSourceServers": ["/api/v1"],
            "exportViewUrl": "/api/v1/viewconfs/",
            "views": [
                {
                    "tracks": {
                        "top": [],
                        "left": [],
                        "center": [
                            {
                                "uid": "",
                                "type": "combined",
                                "contents": [
                                    {
                                        "filetype": "cooler",
                                        "server": f"{higlass_server}/api/v1",
                                        "tilesetUid": map_uuid,
                                        "uid": "",
                                        "type": "heatmap",
                                        "options": {
                                            "heatmapValueScaling": "linear",
                                            "valueScaleMin": 0.0,
                                            "ValueScaleMax": 20.0,
                                        },
                                    },
                                    {
                                        "filetype": "chromsizes-tsv",
                                        "server": f"{higlass_server}/api/v1",
                                        "tilesetUid": grid_uuid,
                                        "uid": "",
                                        "type": "2d-chromosome-grid",
                                        "options": {"lineStrokeWidth": 1, "lineStrokeColor": "grey"},
                                        "width": 20,
                                        "height": 20,
                                    },
                                ],
                                "width": 1583,
                                "height": 788,
                            }
                        ],
                        "right": [],
                        "bottom": [],
                    },
                    "initialXDomain": [0, genome_length],
                    "initialYDomain": [0, genome_length],
                    "layout": {"w": 12, "h": 12, "x": 0, "y": 0, "i": "", "moved": False, "static": False},
                }
            ],
            "zoomLocks": {"locksByViewUid": {}, "locksDict": {}},
            "locationLocks": {"locksByViewUid": {}, "locksDict": {}},
            "valueScaleLocks": {"locksByViewUid": {}, "locksDict": {}},
        },
    }

    headers = {"Content-Type": "application/json"}

    response = requests.post(f"{higlass_server}/api/v1/viewconfs/", json=request_data, headers=headers)

    if response:
        viewconf_uid = response.json()["uid"]
        url = f"{higlass_server}/l/?d=" + viewconf_uid
        return url
    else:
        error_str = "ERROR: Posting view config failed"
        print(error_str)
        sys.exit(1)


def make_dir(path):
    if len(path) > 0:
        os.makedirs(path, exist_ok=True)


def print_output(url, file_out):
    out_dir = os.path.dirname(file_out)
    make_dir(out_dir)
    with open(file_out, "w") as fout:
        fout.write(",".join(["HIGLASS_URL", url]) + "\n")


def main(args=None):
    args = parse_args(args)

    # total genome length is required when creating viewconfig
    length = calculate_genome_size(args.GENOME_FILE)

    # file name is used as the uid for the view config, it can't contain a "."
    file_name = args.FILE_NAME.replace(".", "_")

    # check if already have a viewconfig matching the file name
    exists = check_viewconfig_exists(args.HIGLASS_SERVER, file_name)
    if exists:
        # return existing viewconfig url
        url = f"{args.HIGLASS_SERVER}/l/?d={file_name}"
    else:
        # create a new viewconfig and return the url
        url = request_viewconfig(args.HIGLASS_SERVER, file_name, args.MAP_UUID, args.GRID_UUID, length)

    print_output(url, args.OUTPUT_FILE)


if __name__ == "__main__":
    sys.exit(main())
