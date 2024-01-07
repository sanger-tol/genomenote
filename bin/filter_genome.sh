#!/bin/bash

infile=$1
filter_lst=$2
ord_list=$3

cut -f1,2 "$infile" | sed 's/-/_/g' | sort -k2,2 -nr > "$filter_lst"

if [[ -n "$ord_list" ]]; then
    echo "Working with ordered list"
    new_lst="new_filter.lst"

    while read -r line; do
        grep "$line" "$filter_lst" >> "$new_lst"
    done < "$ord_list"

    grep -v -f "$ord_list" "$filter_lst" >> "$new_lst"

    c1=$(wc -l < "$filter_lst")
    c2=$(wc -l < "$new_lst")

    if [ "$c1" -ne "$c2" ]; then
        echo "The old and new files have a different number of rows."
    fi

    cp "$new_lst" "$filter_lst"
fi

