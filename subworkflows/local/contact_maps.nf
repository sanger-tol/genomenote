//
// Prepare contact maps using aligned reads
//

include { GET_CHROMLIST           } from '../../modules/local/ncbidatasets/get_chromlist'
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
    summary_seq                               // channel: [ meta, summary ]
    cool_bin                                  // channel: val(cooler_bins)
    cool_order                                // path: /path/to/file


    main:
    ch_versions = Channel.empty()


    // Extract the ordered chromosome list
    GET_CHROMLIST ( summary_seq, cool_order.ifEmpty([]) )
    ch_versions = ch_versions.mix ( GET_CHROMLIST.out.versions.first() )


    // CRAM to BAM
    genome
    | map { meta, fasta -> fasta }
    | first
    | set { ch_fasta }

    SAMTOOLS_VIEW ( reads, ch_fasta, [] )
    ch_versions = ch_versions.mix ( SAMTOOLS_VIEW.out.versions.first() )


    // BAM to Bed
    BEDTOOLS_BAMTOBED ( SAMTOOLS_VIEW.out.bam )
    ch_versions = ch_versions.mix ( BEDTOOLS_BAMTOBED.out.versions.first() )


    // Sort the bed file by read name
    BED_SORT ( BEDTOOLS_BAMTOBED.out.bed )
    ch_versions = ch_versions.mix ( BED_SORT.out.versions.first() )


    // Filter the bed file
    // Pair the consecutive rows
    FILTER_BED ( BED_SORT.out.sorted )
    ch_versions = ch_versions.mix ( FILTER_BED.out.versions.first() )


    // Sort the filtered bed by chromosome name
    FILTER_SORT ( FILTER_BED.out.pairs )
    ch_versions = ch_versions.mix ( FILTER_SORT.out.versions.first() )


    // Create the `.cool` file
    FILTER_SORT.out.sorted
    | combine ( cool_bin )
    | map { meta, bed, bin -> [ meta, bed, [], bin ] }
    | set { ch_cooler }

    GET_CHROMLIST.out.list
    | map { meta, list -> list }
    | first
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
