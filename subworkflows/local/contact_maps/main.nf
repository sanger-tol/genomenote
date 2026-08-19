//
// Prepare contact maps using aligned reads
//

include { GET_CHROMLIST      } from '../../../modules/local/ncbidatasets/get_chromlist'
include { SAMTOOLS_VIEW      } from '../../../modules/nf-core/samtools/view/main'
include { HIGLASS_GENERATION } from '../higlass_generation/main'
include { PRETEXT_GENERATION } from '../pretext_generation/main'

workflow CONTACT_MAPS {
    take:
    genome // channel: [ meta, fasta, fai ]
    reads // channel: [ meta, reads, [] ]
    summary_seq // channel: [ meta, summary ]
    cool_bin // channel: val(cooler_bins)
    cooler_seq_order // path: /path/to/file
    contact_map_format // params.contact_map_format

    main:
    ch_versions = channel.empty()

    // Extract the ordered chromosome list
    GET_CHROMLIST(
        summary_seq,
        cooler_seq_order.ifEmpty([]),
    )
    ch_versions = ch_versions.mix(GET_CHROMLIST.out.versions.first())


    // CRAM to BAM
    SAMTOOLS_VIEW(
        reads,
        genome.map { meta, fasta, _fai -> tuple(meta, fasta) }.first(),
        [],
    )
    ch_versions = ch_versions.mix(SAMTOOLS_VIEW.out.versions.first())

    //
    // SUBWORKFLOW: GENERATE THE HIGLASS FILES AND UPLOAD DEPENDING ON USER INPUT
    //
    if (contact_map_format == "higlass" || contact_map_format == "both") {
        HIGLASS_GENERATION(
            SAMTOOLS_VIEW.out.bam,
            GET_CHROMLIST.out.list,
            cool_bin,
        )
        ch_versions = ch_versions.mix(HIGLASS_GENERATION.out.versions.first())

        cooler_file = HIGLASS_GENERATION.out.cool
        mcool_file = HIGLASS_GENERATION.out.mcool
        grid_file = HIGLASS_GENERATION.out.grid
    }
    else {
        cooler_file = channel.empty()
        mcool_file = channel.empty()
        grid_file = channel.empty()
    }

    //
    // SUBWORKFLOW: GENERATE PRETEXT SNAPSHOT FILES
    //
    if (contact_map_format == "pretext" || contact_map_format == "both") {
        PRETEXT_GENERATION(
            genome,
            SAMTOOLS_VIEW.out.bam,
        )
        ch_versions = ch_versions.mix(PRETEXT_GENERATION.out.versions.first())

        pretext_map = PRETEXT_GENERATION.out.pretext_map
        pretext_png = PRETEXT_GENERATION.out.pretext_png
    }
    else {
        pretext_map = channel.empty()
        pretext_png = channel.empty()
    }

    emit:
    cool     = cooler_file // tuple val(meta), val(cool_bin), path("*.cool")
    mcool    = mcool_file // tuple val(meta), path("*.mcool")
    grid     = grid_file // tuple val(meta), path("*.bedpe")
    ptxt_map = pretext_map // tuple val(meta), path("*.pretext")
    ptxt_png = pretext_png // tuple val(meta), path("*.pretext")
    versions = ch_versions // channel: [ versions.yml ]
}
