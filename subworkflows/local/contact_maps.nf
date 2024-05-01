//
// Prepare contact maps using aligned reads
//

include { SAMTOOLS_FAIDX          } from '../../modules/nf-core/samtools/faidx/main'
include { FILTER_GENOME           } from '../../modules/local/filter/genome'
include { SAMTOOLS_VIEW           } from '../../modules/nf-core/samtools/view/main'
include { BEDTOOLS_BAMTOBED       } from '../../modules/nf-core/bedtools/bamtobed/main'
include { GNU_SORT as BED_SORT    } from '../../modules/nf-core/gnu/sort/main'
include { GNU_SORT as FILTER_SORT } from '../../modules/nf-core/gnu/sort/main'
include { FILTER_BED              } from '../../modules/local/filter/bed'
include { COOLER_CLOAD            } from '../../modules/nf-core/cooler/cload/main'
include { COOLER_ZOOMIFY          } from '../../modules/nf-core/cooler/zoomify/main'
include { COOLER_DUMP             } from '../../modules/nf-core/cooler/dump/main'


workflow CONTACT_MAPS {
    take:
    genome                                    // channel: [ meta, fasta ]
    reads                                     // channel: [ meta, reads, [] ]
    cool_bin                                  // channel: val(cooler_bins)


    main:
    ch_versions = Channel.empty()


    // Index genome file
    SAMTOOLS_FAIDX ( genome )
    ch_versions = ch_versions.mix ( SAMTOOLS_FAIDX.out.versions.first() )


    // Filter the genome index file
    FILTER_GENOME ( SAMTOOLS_FAIDX.out.fai )
    ch_versions = ch_versions.mix ( FILTER_GENOME.out.versions.first() )


    // CRAM to BAM
    genome
    | map { meta, fasta -> fasta }
    | set { ch_fasta }

    SAMTOOLS_VIEW ( reads, ch_fasta, [] )
    ch_versions = ch_versions.mix ( SAMTOOLS_VIEW.out.versions.first() )


    // BAM to Bed
    BEDTOOLS_BAMTOBED ( SAMTOOLS_VIEW.out.bam )
    ch_versions = ch_versions.mix ( BEDTOOLS_BAMTOBED.out.versions.first() )


    // Sort the bed file
    BED_SORT ( BEDTOOLS_BAMTOBED.out.bed )
    ch_versions = ch_versions.mix ( BED_SORT.out.versions.first() )


    // Filter the bed file
    FILTER_BED ( BED_SORT.out.sorted )
    ch_versions = ch_versions.mix ( FILTER_BED.out.versions.first() )


    // Sort the filtered bed
    FILTER_SORT ( FILTER_BED.out.pairs )
    ch_versions = ch_versions.mix ( FILTER_SORT.out.versions.first() )


    // Create the `.cool` file
    FILTER_SORT.out.sorted
    | combine ( cool_bin )
    | map { meta, bed, bin -> [ meta, bed, [], bin ] }
    | set { ch_cooler }

    FILTER_GENOME.out.list
    | map { meta, list -> list }
    | set { ch_chromsizes }    

    COOLER_CLOAD ( ch_cooler, ch_chromsizes )
    ch_versions = ch_versions.mix ( COOLER_CLOAD.out.versions.first() )


    // Create the `.mcool` file
    COOLER_CLOAD.out.cool
    | map { meta, cool, bin -> [ meta, cool ] }
    | set { ch_zoomify }

    COOLER_ZOOMIFY ( ch_zoomify )
    ch_versions = ch_versions.mix ( COOLER_ZOOMIFY.out.versions.first() )


    // Create the `.genome` file
    COOLER_CLOAD.out.cool
    | map { meta, cool, bin -> [ meta, cool, [] ] }
    | set { ch_dump }    

    COOLER_DUMP ( ch_dump )
    ch_versions = ch_versions.mix ( COOLER_DUMP.out.versions.first() )


    emit:
    cool     = COOLER_CLOAD.out.cool     // tuple val(meta), val(cool_bin), path("*.cool")
    mcool    = COOLER_ZOOMIFY.out.mcool  // tuple val(meta), path("*.mcool")
    grid     = COOLER_DUMP.out.bedpe     // tuple val(meta), path("*.bedpe")
    versions = ch_versions               // channel: [ versions.yml ]
}
