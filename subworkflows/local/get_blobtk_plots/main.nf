include { BLOBTK_PLOT } from '../../../modules/local/blobtk/plot/main'


workflow GET_BLOBTK_PLOTS {

    take:
    fasta                    // channel: [meta], path/to/fasta
    btk_local_path           // channel: [path/to/dir]
    btk_online_path          // channel: https://online.repository_of_btk.datasets

    main:
    ch_versions         = Channel.empty()

    //
    // NOTE: other arguments for this module, that effect ALL runs of the module
    //          are to be added in modules.config along with scale-factor,
    //          as this is most likely to be adapted by the end user on personal taste.
    //          assembly_level for our purposes can be either 'chromosome' or 'assembled-molecule`
    //              - The first may include unlocalised units whilst the latter will not.
    blobtk_arguments = [
        [
            name: "BLOB_VIEW",
            args: "-v blob"
        ],
        [
            name: "BLOB_CHR_VIEW",
            args: "-v blob --filter assembly_level=assembled-molecule"
        ],
        [
            name: "GRID_VIEW",
            args: "-v blob --shape grid -w 0.01 -x position"
        ],
        [
            name: "GRID_CHR_VIEW_FILTER",
            args: "-v blob --filter assembly_level=assembled-molecule --shape grid -w 0.01 -x position"
        ]
    ]

    //
    // MODULE: Call the specified blobtk server and return grid view of the
    //          assembly position of blob on molecule
    //
    BLOBTK_PLOT (
        fasta,
        btk_local_path,
        btk_online_path,
        blobtk_arguments
    )
    ch_versions         = ch_versions.mix ( BLOBTK_PLOT.out.versions.first() )
    ch_images           = BLOBTK_PLOT.out.png.mix ( BLOBTK_PLOT.out.png )

    emit:
    blobtk_images       = ch_images
    versions            = ch_versions
}
