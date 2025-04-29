//
// Prepare contact maps using aligned reads
//

include { GET_CHROMLIST           } from '../../modules/local/ncbidatasets/get_chromlist'
include { SAMTOOLS_VIEW           } from '../../modules/nf-core/samtools/view/main'
include { HIGLASS_GENERATION      } from './higlass_generation'
include { PRETEXT_GENERATION      } from './pretext_generation'

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
    GET_CHROMLIST (
        summary_seq,
        cool_order.ifEmpty([])
    )
    ch_versions = ch_versions.mix ( GET_CHROMLIST.out.versions.first() )


    // CRAM to BAM
    SAMTOOLS_VIEW (
        reads,
        genome.first(),
        []
    )
    ch_versions = ch_versions.mix ( SAMTOOLS_VIEW.out.versions.first() )

    //
    // SUBWORKFLOW: GENERATE THE HIGLASS FILES AND UPLOAD DEPENDING ON USER INPUT
    //
    HIGLASS_GENERATION (
        SAMTOOLS_VIEW.out.bam,
        GET_CHROMLIST.out.list,
        cool_bin,
        cool_order
    )
    ch_versions = ch_versions.mix ( HIGLASS_GENERATION.out.versions.first() )


    //
    // SUBWORKFLOW: GENERATE PRETEXT SNAPSHOT FILES
    //
    PRETEXT_GENERATION (
        genome,
        GET_CHROMLIST.out.list,
        SAMTOOLS_VIEW.out.bam
    )
    ch_versions = ch_versions.mix ( PRETEXT_GENERATION.out.versions.first() )


    emit:
    cool     = HIGLASS_GENERATION.out.cool               // tuple val(meta), val(cool_bin), path("*.cool")
    mcool    = HIGLASS_GENERATION.out.mcool              // tuple val(meta), path("*.mcool")
    grid     = HIGLASS_GENERATION.out.grid               // tuple val(meta), path("*.bedpe")
    link     = HIGLASS_GENERATION.out.link               // channel: [ *_higlass_link.csv]
    ptxt_map = PRETEXT_GENERATION.out.pretext_map        // tuple val(meta), path("*.pretext")
    ptxt_png = PRETEXT_GENERATION.out.pretext_png        // tuple val(meta), path("*.pretext")
    versions = ch_versions                               // channel: [ versions.yml ]
}
