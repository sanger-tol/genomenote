#!/bin/bash

infile=$1
filter_lst=$2
ord_list=$3

jq -r '.reports[] | [.genbank_accession, .length] | @tsv' < "$infile" | sort -k2,2 -nr > "$filter_lst"

if [[ -n "$ord_list" ]]; then
    echo "Working with ordered list"
    new_lst="new_filter.lst"

    while read -r line; do
        grep -F "$line" "$filter_lst"
    done < "$ord_list" > "$new_lst"

    grep -v -F -f "$ord_list" "$filter_lst" >> "$new_lst"

    c1=$(wc -l < "$filter_lst")
    c2=$(wc -l < "$new_lst")

    if [ "$c1" -ne "$c2" ]; then
        echo "The old and new files have a different number of rows."
        exit 1
    fi

    cp "$new_lst" "$filter_lst"
fi

