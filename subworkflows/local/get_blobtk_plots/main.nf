include { BLOBTK_PLOT } from '../../../modules/local/blobtk/plot/main'


workflow GET_BLOBTK_PLOTS {

    take:
    fasta                    // channel: [meta], path/to/fasta
    btk_address              // channel: https://blobserver.org

    main:
    ch_versions         = Channel.empty()

    blobtk_arguments = [
        [
            name: "BLOB_VIEW",
            args: "-v blob --scale-factor 0.6"
        ],
        [
            name: "BLOB_CHR_VIEW",
            args: "-v blob --filter assembly_level=chromosome --scale-factor 0.6"
        ],
        [
            name: "GRID_VIEW",
            args: "-v blob --shape grid -w 0.01 -x position --scale-factor 0.6"
        ],
        [
            name: "GRID_CHR_VIEW_FILTER",
            args: "-v blob --filter assembly_level=chromosome --shape grid -w 0.01 -x position --scale-factor 0.6"
        ]
    ]

    //
    // MODULE: Call the specified blobtk server and return grid view of the
    //          assembly position of blob on molecule
    //
    BLOBTK_PLOT (
        fasta,
        btk_address,
        blobtk_arguments
    )
    ch_versions         = ch_versions.mix ( BLOBTK_PLOT.out.versions.first() )
    ch_images           = BLOBTK_PLOT.out.png.mix ( BLOBTK_PLOT.out.png )

    emit:
    blobtk_images       = ch_images
    versions            = ch_versions
}
