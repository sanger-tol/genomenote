//
// Prepare contact maps using aligned reads
//
include { SAMTOOLS_FAIDX          } from '../../modules/nf-core/samtools/faidx/main'
include { GENOME_FILTER           } from '../../modules/local/genome_filter'
include { SAMTOOLS_VIEW           } from '../../modules/nf-core/samtools/view/main'
include { BEDTOOLS_BAMTOBED       } from '../../modules/nf-core/bedtools/bamtobed/main'
include { GNU_SORT as BED_SORT    } from '../../modules/local/gnu_sort'
include { GNU_SORT as FILTER_SORT } from '../../modules/local/gnu_sort'
include { BED_FILTER              } from '../../modules/local/bed_filter'
include { COOLER_CLOAD            } from '../../modules/nf-core/cooler/cload/main'
include { COOLER_ZOOMIFY          } from '../../modules/nf-core/cooler/zoomify/main'

workflow CONTACT_MAPS {
    take:
    genome                                    // channel: [ meta, fasta ]
    reads                                     // channel: [ meta, reads, [] ]
    cool_bin                                  // channel: val(cooler_bins)

    main:
    ch_versions = Channel.empty()

    // Index genome file
    SAMTOOLS_FAIDX ( genome )
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions.first())

    // Filter the genome index file
    GENOME_FILTER ( SAMTOOLS_FAIDX.out.fai )
    ch_versions = ch_versions.mix(GENOME_FILTER.out.versions.first())

    // CRAM to BAM
    ch_fasta = genome.map { meta, fasta -> fasta }
    SAMTOOLS_VIEW ( reads, ch_fasta, [] )
    ch_versions = ch_versions.mix(SAMTOOLS_VIEW.out.versions.first())
    
    // BAM to Bed
    BEDTOOLS_BAMTOBED ( SAMTOOLS_VIEW.out.bam )
    ch_versions = ch_versions.mix(BEDTOOLS_BAMTOBED.out.versions.first())

    // Sort the bed file
    BED_SORT ( BEDTOOLS_BAMTOBED.out.bed )
    ch_versions = ch_versions.mix(BED_SORT.out.versions.first())

    // Filter the bed file
    BED_FILTER ( BED_SORT.out.bed )
    ch_versions = ch_versions.mix(BED_FILTER.out.versions.first())

    // Sort the filtered bed
    FILTER_SORT ( BED_FILTER.out.pairs )
    ch_versions = ch_versions.mix(FILTER_SORT.out.versions.first())

    // Create the `.cool` file
    ch_cooler = FILTER_SORT.out.bed.combine(cool_bin).map { meta, bed, bin -> [ meta, bed, [], bin ] }
    COOLER_CLOAD ( ch_cooler, GENOME_FILTER.out.list )
    ch_versions = ch_versions.mix(COOLER_CLOAD.out.versions).first()

    // Create the `.mcool` file
    ch_zoomify = COOLER_CLOAD.out.cool.map { meta, cool, bin -> [ meta, cool ] }
    COOLER_ZOOMIFY ( ch_zoomify )
    ch_versions = ch_versions.mix(COOLER_ZOOMIFY.out.versions.first())

    emit:
    cool = COOLER_CLOAD.out.cool      // tuple val(meta), val(cool_bin), path("*.cool")
    mcool = COOLER_ZOOMIFY.out.mcool  // tuple val(meta), path("*.mcool")
    versions = ch_versions            // channel: [ versions.yml ]
}
