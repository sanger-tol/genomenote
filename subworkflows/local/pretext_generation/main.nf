include { PRETEXTMAP      } from '../../../modules/nf-core/pretextmap/main'
include { PRETEXTSNAPSHOT } from '../../../modules/nf-core/pretextsnapshot/main'

workflow PRETEXT_GENERATION {
    take:
    genome // Channel [ val(meta), path(fasta), path(fai) ]
    bam_tuple // Channel [ val(meta), path(file)      ]

    main:
    ch_versions = channel.empty()

    //
    // MODULE: GENERATE PRETEXT MAP FROM MAPPED BAM - These are already aligned so we don't need any more processing
    //
    PRETEXTMAP(
        bam_tuple,
        genome.map { meta, fasta, _fai -> tuple(meta, fasta) }.collect(),
        genome.map { meta, _fasta, fai -> tuple(meta, fai) }.collect(),
    )
    ch_versions = ch_versions.mix(PRETEXTMAP.out.versions)


    //
    // MODULE: GENERATE PNG FROM PRETEXT MAP
    //
    PRETEXTSNAPSHOT(
        PRETEXTMAP.out.pretext
    )
    ch_versions = ch_versions.mix(PRETEXTSNAPSHOT.out.versions)

    emit:
    pretext_map = PRETEXTMAP.out.pretext // tuple val(meta), path("*.pretext")
    pretext_png = PRETEXTSNAPSHOT.out.image // tuple val(meta), path("*.pretext")
    versions    = ch_versions // channel: [ versions.yml ]
}
