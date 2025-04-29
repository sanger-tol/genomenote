#!/usr/bin/env python

VERSION = "V2.0.0"

DESCRIPTION = """
        process_snapshot.py
-----------------------------------
This script takes the snapshot and an index file
to annotate the snapshot with the chromosome names
on the x and y axes.

Version 1 (process_images.py) was written by Karen Houliston
with help from ChatGPT. Script is written as an imported function
as part of a larger collection of scripts to generate genome_note_articles.

# 17-18 Jan 2025  main script reconfigured
# 16 Feb 2025 now searches ensembl beta site for annotation
# 13 March updated method of getting each tolid for each technology if they are not in COPO.
# 23 March 2025 Add method to add all parent projects to Data availability section and 9 April modify the list of parent projects in template
# 12 April 2025 introduced tenacity and shared utility module ncbi_requests.py to help with 429 and 502 errors.
# 17 April 2025 added extraction_data module to use tol-sdk to fetch benchling extraction information
# 18 April added labelling of PretextSnapshot map

Version 2 (process_snapshot.py) has been written by Damon-Lee Pointon

28/04/2025
- Refactor to standalone script
- Use ArgParse for command line arguments
- Remove option for total genome length - easier to calc from chromosome list

"""

from PIL import Image, ImageDraw, ImageFont
import argparse
import textwrap
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(),  # logs to terminal
        logging.FileHandler("process_snapshot_run.log"),  # logs to file
    ],
)


def parse_args(arg=None):
    parser = argparse.ArgumentParser(
        prog="Process Snapshot",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=textwrap.dedent(DESCRIPTION),
    )
    parser.add_argument("--input_png", required=True, type=str, help="Path to the pretext snapshot PNG")
    parser.add_argument("--chromosome_list", required=True, type=str, help="Chromosome list file")
    parser.add_argument("--output_path", type=str, help="Output path for labelled image", default="output.png")
    parser.add_argument(
        "--font_path", type=str, help="Path to the font file", default="../assets/Roboto-VariableFont_wdth,wght.ttf"
    )
    parser.add_argument("--font_size", type=int, help="Font size for labels", default=40)
    parser.add_argument("--min_fraction", type=float, help="Minimum fraction for labels", default=0.01)
    parser.add_argument(
        "--exclude_molecules", type=str, help="List of molecules to exclude from labelling", default=list()
    )
    parser.add_argument(
        "--background_colour", type=str, help="Background colour for the labelled image", default="white"
    )
    parser.add_argument("--text_colour", type=str, help="Text colour for the labels", default="black")
    parser.add_argument("--label_padding", type=int, help="Padding for the labels", default=4)
    parser.add_argument("-v", "--version", action="version", version=VERSION)
    return parser.parse_args()


def filter_chromosomes(chromosome_list, exclude_molecules, min_fraction):
    """
    Filter out the excluded molecules and small unlocs from the chromosome list.
    """
    max_length = max(c["length"] for c in chromosome_list)
    filtered_chromosomes = [
        c
        for c in chromosome_list
        if c["molecule"] not in exclude_molecules and c["length"] >= min_fraction * max_length
    ]

    return sorted(filtered_chromosomes, key=lambda x: x["length"], reverse=True)


def main(args=None):
    args = parse_args(args)
    logging.info("Starting process_snapshot.py")
    logging.info(f"Input PNG: {args.input_png}")
    logging.info(f"Chromosome list: {args.chromosome_list}")
    logging.info(f"Output path: {args.output_path}")

    filter_chromosomes = filter_chromosomes(args.chromosome_list, args.exclude_molecules, args.min_fraction)

    with Image.open(args.input_png) as original:
        width, height = original.size

        # Compute extra margin based on font size
        try:
            font = ImageFont.truetype(args.font_path, size=args.font_size)
        except Exception:
            font = ImageFont.load_default()

        bbox = font.getbbox("22")
        label_height = bbox[3] - bbox[1]
        extra_margin_bottom = label_height + 50
        extra_margin_left = label_height + 50

        # Create new image with extra margin
        new_img = Image.new("RGB", (width + extra_margin_left, height + extra_margin_bottom), args.background_colour)
        new_img.paste(original, (extra_margin_left, 0))
        draw = ImageDraw.Draw(new_img)

        # Compute x/y-positions based on proportion of genome
        total_length = sum(c["length"] for c in args.chromosomes_sorted)

        x_positions = []
        accum_length = 0
        for c in filter_chromosomes:
            chr_width = (c["length"] / total_length) * width
            midpoint = accum_length + chr_width / 2
            x_positions.append(midpoint)
            accum_length += chr_width

        # Draw horizontal labels below the image
        for i, chrom in enumerate(filter_chromosomes):
            label = chrom["molecule"]
            x = x_positions[i] + extra_margin_left
            y = height + 10
            bbox = font.getbbox(label)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]

            draw.rectangle(
                [
                    (x - text_width / 2 - args.padding, y - args.padding),
                    (x + text_width / 2 + args.padding, y + text_height + args.padding),
                ],
                fill=args.background_colour,
            )
            draw.text((x - text_width / 2, y), label, fill=args.text_colour, font=font)

        # Draw vertical labels to the left of the image (upright)
        for i, chrom in enumerate(filter_chromosomes):
            label = chrom["molecule"]
            y = x_positions[i]  # reusing x_positions for vertical axis
            x = 30

            bbox = font.getbbox(label)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]

            draw.rectangle(
                [
                    (x - args.padding, y - text_height / 2 + args.padding),
                    (x + text_width + args.padding, y + text_height / 2 + args.padding),
                ],
                fill=args.background_colour,
            )
            draw.text((x, y - text_height / 2), label, fill=args.text_colour, font=font)

        logging.info(f"🧷 Using font size {args.font_size}, padding {args.padding}")

        new_img.save(args.output_path)


if __name__ == "__main__":
    main()
