//
// Prepare contact maps using aligned reads
//

include { GET_CHROMLIST                                     } from '../../../modules/local/ncbidatasets/get_chromlist'
include { SAMTOOLS_VIEW                                     } from '../../../modules/nf-core/samtools/view/main'
include { HIGLASS_GENERATION                                } from '../higlass_generation/main'
include { PRETEXT_GENERATION                                } from '../pretext_generation/main'
include { PRETEXT_GENERATION as COMBINED_PRETEXT_GENERATION } from '../pretext_generation/main'
include { CAT_CAT                                           } from '../../../modules/nf-core/cat/cat/main'

workflow CONTACT_MAPS {
    take:
    primary_assembly                          // channel: [ meta, fasta ]
    haplotype_assembly                        // channel: [ meta, fasta ]
    reads                                     // channel: [ meta, reads, [] ]
    summary_seq                               // channel: [ meta, summary ]
    cool_bin                                  // channel: val(cooler_bins)
    cool_order                                // path: /path/to/file
    select_contact_map                        // params.select_contact_map


    main:
    ch_versions     = Channel.empty()
    pretext_map     = Channel.empty()
    pretext_png     = Channel.empty()

    // Extract the ordered chromosome list
    GET_CHROMLIST (
        summary_seq,
        cool_order.ifEmpty([])
    )
    ch_versions     = ch_versions.mix ( GET_CHROMLIST.out.versions.first() )


    // CRAM to BAM
    SAMTOOLS_VIEW (
        reads,
        primary_assembly.first(),
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
    // SUBWORKFLOW: GENERATE PRETEXT MAP AND SNAPSHOT FILES
    //
    if ( select_contact_map == "pretext" || select_contact_map == "both" ) {
        PRETEXT_GENERATION (
            primary_assembly,
            GET_CHROMLIST.out.list,
            SAMTOOLS_VIEW.out.bam
        )
        ch_versions = ch_versions.mix ( PRETEXT_GENERATION.out.versions.first() )

        pretext_map.mix( PRETEXT_GENERATION.out.pretext_map )
        pretext_png.mix( PRETEXT_GENERATION.out.pretext_png )
    }


    //
    // SUBWORKFLOW: GENERATE A COMBINED PRETEXT MAP AND SNAPSHOT FILES
    //              USING HAP1 AND HAP2
    //
    if (
        (select_contact_map == "pretext" || select_contact_map == "both" ) &&
        params.combined_maps
    ) {

        //
        // LOGIC: RENAME THE META'S BAM META CONTROLS NAMING IN PRETEXTMAP
        //
        SAMTOOLS_VIEW.out.bam
            .map { meta, bam ->
                def new_meta = meta + [id: "${meta.id}_combined"]
                [new_meta, bam]
            }
            .set { combined_bam }


        primary_assembly
            .combine ( haplotype_assembly )
            .map { meta_1, primary, meta_2, haplotype ->
                // This will mean the output files for everything downstream
                // will contain combined to differentiate them
                def new_meta = meta_1 + [id: "${meta_1.id}_combined"]
                [new_meta, [primary, haplotype]]
            }
            .set { merge_channel }


        //
        // MODULE: CONCATENATE THE PRIMARY AND HAPLOTYPE ASSEMBLIES
        //
        CAT_CAT (
            merge_channel
        )
        ch_versions = ch_versions.mix ( CAT_CAT.out.versions.first() )


        COMBINED_PRETEXT_GENERATION (
            CAT_CAT.out.file_out,
            [[],[]],
            combined_bam
        )
        ch_versions = ch_versions.mix ( COMBINED_PRETEXT_GENERATION.out.versions.first() )

        pretext_map.mix( COMBINED_PRETEXT_GENERATION.out.pretext_map )
        pretext_png.mix( COMBINED_PRETEXT_GENERATION.out.pretext_png )
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
