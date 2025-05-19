include { BLOBTK_PLOT as BLOBTK_PLOT_GRID_VIEW          } from '../../../modules/local/blobtk/plot/main'
// include { BLOBTK_PLOT as BLOBTK_PLOT_LINEAR_VIEW          } from '../../../modules/local/blobtk/plot/main'
// include { BLOBTK_PLOT as BLOBTK_PLOT_SOMETHING_ELSE          } from '../../../modules/local/blobtk/plot/main'


workflow GET_BLOBTK_PLOTS {

    take:
    fasta                    // channel: [meta], path/to/fasta
    btk_address              // channel: https://blobserver.org

    main:
    ch_versions =   Channel.empty()

    //
    // MODULE: Call the specified blobtk server and return a custom png
    //
    BLOBTK_PLOT_GRID_VIEW (
        fasta,
        btk_address
    )
    ch_versions =   ch_versions.mix ( BLOBTK_PLOT_GRID_VIEW.out.versions.first() )

    // BLOBTK_PLOT_LINEAR_VIEW

    emit:
    grid_view   = BLOBTK_PLOT_GRID_VIEW.out.png
}
