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
    select_contact_map                        // params.select_contact_map


    main:
    ch_versions     = Channel.empty()

    // Extract the ordered chromosome list
    GET_CHROMLIST (
        summary_seq,
        cool_order.ifEmpty([])
    )
    ch_versions     = ch_versions.mix ( GET_CHROMLIST.out.versions.first() )


    // CRAM to BAM
    SAMTOOLS_VIEW (
        reads,
        genome.first(),
        []
    )
    ch_versions     = ch_versions.mix ( SAMTOOLS_VIEW.out.versions.first() )

    //
    // SUBWORKFLOW: GENERATE THE HIGLASS FILES AND UPLOAD DEPENDING ON USER INPUT
    //
    if ( select_contact_map == "higlass" || select_contact_map == "both" ) {
        HIGLASS_GENERATION (
            SAMTOOLS_VIEW.out.bam,
            GET_CHROMLIST.out.list,
            cool_bin,
            cool_order
        )
        ch_versions = ch_versions.mix ( HIGLASS_GENERATION.out.versions.first() )

        cooler_file = HIGLASS_GENERATION.out.cool
        mcool_file  = HIGLASS_GENERATION.out.mcool
        grid_file   = HIGLASS_GENERATION.out.grid
        link_file   = HIGLASS_GENERATION.out.link
    } else {
        cooler_file = Channel.empty()
        mcool_file  = Channel.empty()
        grid_file   = Channel.empty()
        link_file   = Channel.empty()
    }

    //
    // SUBWORKFLOW: GENERATE PRETEXT SNAPSHOT FILES
    //
    if ( select_contact_map == "pretext" || select_contact_map == "both" ) {
        PRETEXT_GENERATION (
            genome,
            GET_CHROMLIST.out.list,
            SAMTOOLS_VIEW.out.bam
        )
        ch_versions = ch_versions.mix ( PRETEXT_GENERATION.out.versions.first() )

        pretext_map = PRETEXT_GENERATION.out.pretext_map
        pretext_png = PRETEXT_GENERATION.out.pretext_png
    } else {
        pretext_map = Channel.empty()
        pretext_png = Channel.empty()
    }


    emit:
    cool     = cooler_file      // tuple val(meta), val(cool_bin), path("*.cool")
    mcool    = mcool_file       // tuple val(meta), path("*.mcool")
    grid     = grid_file        // tuple val(meta), path("*.bedpe")
    link     = link_file        // channel: [ *_higlass_link.csv]
    ptxt_map = pretext_map      // tuple val(meta), path("*.pretext")
    ptxt_png = pretext_png      // tuple val(meta), path("*.pretext")
    versions = ch_versions      // channel: [ versions.yml ]
}
