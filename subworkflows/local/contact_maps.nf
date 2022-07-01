//
// Prepare contact maps using aligned reads
//
include { BEDTOOLS_BAMTOBED       } from '../../modules/local/bedtools_bamtobed'
include { GENOME_FILTER           } from '../../modules/local/genome_filter'
include { GNU_SORT as BED_SORT    } from '../../modules/local/gnu_sort'
include { GNU_SORT as FILTER_SORT } from '../../modules/local/gnu_sort'
include { BED_FILTER              } from '../../modules/local/bed_filter'
include { COOLER_CLOAD            } from '../../modules/nf-core/modules/cooler/cload/main'
include { COOLER_ZOOMIFY          } from '../../modules/nf-core/modules/cooler/zoomify/main'

workflow CONTACT_MAPS {
    take:
    aln                                       // channel: [ val(meta), [ datafile ] ]
    index                                     // channel: fai
    cool_bin                                  // channel: val(cooler_bins)

    main:
    ch_versions = Channel.empty()

    // Bam to Bed
    BEDTOOLS_BAMTOBED ( aln )
    ch_versions = ch_versions.mix(BEDTOOLS_BAMTOBED.out.versions)

    // Filter the genome index file
    GENOME_FILTER ( index )
    ch_versions = ch_versions.mix(GENOME_FILTER.out.versions)

    // Sort the bed file
    BED_SORT ( BEDTOOLS_BAMTOBED.out.bed )
    ch_versions = ch_versions.mix(BED_SORT.out.versions)

    // Filter the bed file
    BED_FILTER ( BED_SORT.out.bed )
    ch_versions = ch_versions.mix(BED_FILTER.out.versions)

    // Sort the filtered bed
    FILTER_SORT ( BED_FILTER.out.pairs )
    ch_versions = ch_versions.mix(FILTER_SORT.out.versions)

    FILTER_SORT.out.bed
    .map { meta, bed ->
    [ meta, bed, [] ]
    }
    .set { ch_cooler }
    
    // Create the `.cool` file
    COOLER_CLOAD ( ch_cooler, cool_bin, GENOME_FILTER.out.list )
    ch_versions = ch_versions.mix(COOLER_CLOAD.out.versions)
    COOLER_CLOAD.out.cool.view()

    COOLER_CLOAD.out.cool
    .map { meta, bin, cool ->
    [ meta, cool ]
    }
    .set { ch_zoomify }

    // Create the `.mcool` file
    COOLER_ZOOMIFY ( ch_zoomify )
    ch_versions = ch_versions.mix(COOLER_ZOOMIFY.out.versions)
    COOLER_ZOOMIFY.out.mcool.view()

    emit:
    cool = COOLER_CLOAD.out.cool      // tuple val(meta), val(cool_bin), path("*.cool")
    mcool = COOLER_ZOOMIFY.out.mcool  // tuple val(meta), path("*.mcool")
    versions = ch_versions            // channel: [ versions.yml ]
}
