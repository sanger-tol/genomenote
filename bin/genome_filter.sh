#!/bin/bash

index=$1
outfile=$2

cut -f1,2 $index | sed 's/-/_/g' | sort -k2,2 -nr > $outfile
