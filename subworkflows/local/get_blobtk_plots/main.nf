include { BLOBTK_PLOT as BLOBTK_PLOT_GRID_VIEW              } from '../../../modules/local/blobtk/plot/main'
include { BLOBTK_PLOT as BLOBTK_PLOT_GRID_CHR_ONLY_VIEW     } from '../../../modules/local/blobtk/plot/main'
include { BLOBTK_PLOT as BLOBTK_PLOT_DEFAULT_VIEW           } from '../../../modules/local/blobtk/plot/main'
include { BLOBTK_PLOT as BLOBTK_PLOT_DEFAULT_CHR_ONLY_VIEW  } from '../../../modules/local/blobtk/plot/main'


workflow GET_BLOBTK_PLOTS {

    take:
    fasta                    // channel: [meta], path/to/fasta
    btk_address              // channel: https://blobserver.org

    main:
    ch_versions         = Channel.empty()

    //
    // MODULE: Call the specified blobtk server and return grid view of the
    //          assembly position of blob on molecule
    //
    BLOBTK_PLOT_GRID_VIEW (
        fasta,
        btk_address
    )
    ch_versions         = ch_versions.mix ( BLOBTK_PLOT_GRID_VIEW.out.versions.first() )


    //
    // MODULE: Call the specified blobtk server and return grid view of the
    //          assembly position of blob on molecule
    //              This is filtered for chromosomes only
    //
    BLOBTK_PLOT_GRID_CHR_ONLY_VIEW (
        fasta,
        btk_address
    )
    ch_versions         = ch_versions.mix ( BLOBTK_PLOT_GRID_CHR_ONLY_VIEW.out.versions.first() )


    //
    // MODULE: Call the specified blobtk server and return the default blob plot
    //
    BLOBTK_PLOT_DEFAULT_VIEW (
        fasta,
        btk_address
    )
    ch_versions         = ch_versions.mix ( BLOBTK_PLOT_DEFAULT_VIEW.out.versions.first() )


    //
    // MODULE: Call the specified blobtk server and return the default blob plot
    //              This is filtered for chromosomes only
    //
    BLOBTK_PLOT_DEFAULT_CHR_ONLY_VIEW (
        fasta,
        btk_address
    )
    ch_versions         = ch_versions.mix ( BLOBTK_PLOT_DEFAULT_CHR_ONLY_VIEW.out.versions.first() )




    emit:
    grid_view           = BLOBTK_PLOT_GRID_VIEW.out.png
    filtered_grid_view  = BLOBTK_PLOT_GRID_CHR_ONLY_VIEW.out.png
    blob_view           = BLOBTK_PLOT_DEFAULT_VIEW.out.png
    filtered_blob_view  = BLOBTK_PLOT_DEFAULT_CHR_ONLY_VIEW.out.png
    versions            = ch_versions
}
