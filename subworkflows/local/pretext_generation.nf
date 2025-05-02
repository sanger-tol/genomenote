include { SAMTOOLS_FAIDX    } from '../../modules/nf-core/samtools/faidx/main'
include { PRETEXTMAP        } from '../../modules/nf-core/pretextmap/main'
include { PRETEXTSNAPSHOT   } from '../../modules/nf-core/pretextsnapshot/main'

workflow PRETEXT_GENERATION {
    take:
    genome          // Channel [ val(meta), path(file)      ]
    chrom_list      // Channel [ val(meta), path(file)      ]
    bam_tuple       // Channel [ val(meta), path(file)      ]

    main:
    ch_versions     = Channel.empty()

    //
    // MODULE: GENERATE FAI FILE FROM FASTA
    //         THIS CAN LIKELY BE MOVED TO THE MAIN WORKFLOW IN THE FUTURE
    //         AS MULTIPLE PR's USE THIS MODULE
    //
    SAMTOOLS_FAIDX (
        genome,
        [[],[]],
        false
    )
    ch_versions     = ch_versions.mix( SAMTOOLS_FAIDX.out.versions )


    //
    // MODULE: GENERATE PRETEXT MAP FROM MAPPED BAM - These are already aligned so we don't need any more processing
    //
    PRETEXTMAP (
        bam_tuple,
        genome,
        SAMTOOLS_FAIDX.out.fai
    )
    ch_versions     = ch_versions.mix( PRETEXTMAP.out.versions )


    //
    // MODULE: GENERATE PNG FROM PRETEXT MAP
    //
    PRETEXTSNAPSHOT (
        PRETEXTMAP.out.pretext
    )
    ch_versions     = ch_versions.mix( PRETEXTSNAPSHOT.out.versions )


    emit:
    pretext_map     = PRETEXTMAP.out.pretext        // tuple val(meta), path("*.pretext")
    pretext_png     = PRETEXTSNAPSHOT.out.image     // tuple val(meta), path("*.pretext")
    versions        = ch_versions                   // channel: [ versions.yml ]
}
