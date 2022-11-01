#!/bin/bash


if [ $# -ne 2 ]; then echo -e "Script to create a samplesheet for a species.\nUsage: $0 <tol_id> <tol_project_dir>.\nVersion: 1.1"; exit 1; fi

id="$1"
data="$2/data"

if [[ ! -d "$data" ]]
then
    echo "Project directory " $data " does not exist."
    exit 1
fi

if compgen -G $data/*/*/assembly/release/${id}.[0-9]/insdc/GCA*fasta.gz > /dev/null
    then genome=$(ls $data/*/*/assembly/release/${id}.[0-9]/insdc/GCA*fasta.gz | tail -1)
elif compgen -G $data/*/*/assembly/release/${id}.[0-9]_{p,m}aternal_haplotype/insdc/GCA*fasta.gz > /dev/null
    then genome=$(ls $data/*/*/assembly/release/${id}.[0-9]_*aternal_haplotype/insdc/GCA*fasta.gz | tail -1)
else echo "Genome for $id not found in $data"; exit 1; fi

taxon=$(echo $genome | cut -f8 -d'/')
organism=$(echo $genome | cut -f9 -d'/')
assembly=$(echo $genome | cut -f12 -d'/')
gca=$(echo $genome | cut -f14 -d'/' | sed 's/.fasta.gz//')

# Currently this will import a masked file, but once the `insdcdownload` pipeline goes in production, it will be unmasked
ln -s $genome

analysis=$data/$taxon/$organism/analysis/$assembly

if compgen -G $analysis/read_mapping/hic*/${gca}.*cram > /dev/null
    then echo "sample,datatype,datafile" > samplesheet.csv
    crams=($(ls $analysis/read_mapping/hic*/${gca}.*cram))
    for aln in ${crams[@]}
        do sample=$(basename $aln | awk -F. '{print $(NF-1)}')
        echo "${sample},hic,${aln}" >> samplesheet.csv
    done
else echo "No cram files."; exit 1; fi

gdata=$data/$taxon/$organism/genomic_data

if compgen -G $gdata/*/pacbio/kmer > /dev/null
    then kmer=($(ls -d $data/*/*/genomic_data/*/pacbio/kmer/*))
    datatype="pacbio"
elif compgen -G $gdata/*/illumina/kmer > /dev/null
    then kmer=($(ls -d $data/*/*/genomic_data/*/illumina/kmer/*))
    datatype="illumina"
elif compgen -G $gdata/*/10x/kmer > /dev/null
    then kmer=($(ls -d $data/*/*/genomic_data/*/10x/kmer/*))
    datatype="10x"
else echo "No kmer folders found."; exit 1; fi

for dloc in ${kmer[@]}
    do sample=$(echo $dloc | cut -d'/' -f11)
    kval=$(basename $dloc)
    echo "${sample},${datatype}_${kval},$dloc" >> samplesheet.csv
done
