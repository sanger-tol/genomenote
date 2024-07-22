#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Obtain the summary statistic of the genome features from the General feature format file (GFF3)

process CountFeatures {
    publishDir "${params.outdir}/annotation_statistics", mode: 'copy'
    tag "$gff3_file"

    conda "${params.projectDir}/modules/nf-core/gt/stat/environment.yml"

    container 'https://depot.galaxyproject.org/singularity/genometools-genometools:1.6.5--py310h3db02ab_0'

    input:
    path gff3_file

    output:
    path "assembly_ID.csv"

    script:
    """

    gt stat ${gff3_file} | awk -F ': ' 'BEGIN {OFS="\t"; print "variable", "value"} {
    value = substr(\$0, index(\$0, ":") + 1);  // Get everything after the first colon
    print \$1, value}' > assembly_ID.csv

    """
}


// Extract the exon informtion : position and attribute information
process ExtractExons {

    publishDir "${params.outdir}/annotation_statistics/Exon_information", mode: 'copy'
    tag "$gff3_file"
    input:
    path gff3_file

    output:
    path "exons.txt"

    script:
    """

    cat ${gff3_file} | awk '!/^#/ && \$3 == "exon"  {print \$1, \$4, \$5 , \$7 , \$9 }' > exons.txt
    """
}


// Obtain the intron length from the exon information

process IntronLength {
    publishDir "${params.outdir}/annotation_statistics/Intron_length", mode: 'copy'

    input:
    path "exons.txt"

    output:
    path "intron_lengths.txt"

    script:
    """
    awk '
    {
        if (\$1 == last_chrom && \$4 == last_strand) {
            intron_length = \$2 - last_end - 1
            if (intron_length > 0) {
                print intron_length
            }
        }
        last_chrom = \$1
        last_start = \$2
        last_end = \$3
        last_strand = \$4
    }' exons.txt > intron_lengths.txt
    """
}

// Obtain the total count of introns

process CalculateIntronStats {
    input:
    path "intron_lengths.txt"

    output:
    path "intron_stats.txt"

    script:
    """
    INTRON_COUNT=\$(wc -l < intron_lengths.txt)
    INTRON_TOTAL_LENGTH=\$(awk '{sum+=\$1} END {print sum}' intron_lengths.txt)
    INTRON_AVG_LENGTH=\$(awk '{sum+=\$1} END {if (NR > 0) print sum/NR}' intron_lengths.txt)
    echo "intron \$INTRON_COUNT" > intron_stats.txt
    """
}

// Add the intron count to the initial feature count and tabulate the results

process TabulateResults {
    publishDir "${params.outdir}/annotation_statistics", mode: 'copy'
    input:
    path "assembly_ID.csv"
    path "intron_stats.txt"

    output:
    path "summary_table.txt"

    script:
    """
    echo " Table showing the summary statistics for the genome features " > summary_table.txt
    cat assembly_ID.csv >> summary_table.txt
    cat intron_stats.txt >> summary_table.txt
    """
}
