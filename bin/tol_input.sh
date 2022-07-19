#!/bin/bash

if [ ! $# -eq 2 ]; then echo -e "Please provide a ToL ID. \nUsage: ./tol_input.sh <tol_id> <tol_project>. \n<tol_id> must match the expected genome. \n<tol_project> name of the tree of life project."; exit 1; fi

id=$1
project=$2
data=/lustre/scratch124/tol/projects/$project/data

if compgen -G $data/*/*/assembly/release/${id}.[0-9]/insdc/GCA*fasta.gz > /dev/null
    then genome=$(ls $data/*/*/assembly/release/${id}.[0-9]/insdc/GCA*fasta.gz | tail -1)
elif compgen -G $data/*/*/assembly/release/${id}.[0-9]_{p,m}aternal_haplotype/insdc/GCA*fasta.gz > /dev/null
    then genome=$(ls $data/*/*/assembly/release/${id}.[0-9]_*aternal_haplotype/insdc/GCA*fasta.gz | tail -1)
else echo "Genome for $id not found"; exit 1; fi

taxon=$(echo $genome | cut -f8 -d'/')
organism=$(echo $genome | cut -f9 -d'/')
assembly=$(echo $genome | cut -f12 -d'/')
gca=$(echo $genome | cut -f14 -d'/' | sed 's/.fasta.gz//')

analysis=$data/$taxon/$organism/analysis/$assembly

if compgen -G $analysis/read_mapping/hic*/${gca}.*cram > /dev/null
    then echo "sample,datatype,datafile" > samplesheet.csv
    crams=($(ls $analysis/read_mapping/hic*/${gca}.*cram))
    for aln in ${crams[@]}
        do sample=$(basename $aln | awk -F. '{print $(NF-1)}')
        datatype=$(basename $aln | awk -F. '{print $(NF-2)}')
        echo "${sample},${datatype},${aln}" >> samplesheet.csv
    done
else echo "No cram files."; exit 1; fi

if compgen -G $analysis/assembly/indices/${gca}.unmasked.fasta > /dev/null
    then ln -s $analysis/assembly/indices/${gca}.unmasked.fasta unmasked_genome.fasta
else "Unmasked fasta does not exist."; exit 1; fi

