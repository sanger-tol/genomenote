include { BLOBTK_PLOT } from '../../../modules/nf-core/blobtk/plot/main'


workflow GET_BLOBTK_PLOTS {
    take:
    fasta // channel: [meta], path/to/fasta
    btk_local_path // channel: [path/to/dir]
    btk_online_path // channel: https://online.repository_of_btk.datasets

    main:

    //
    // NOTE: other arguments for this module, that effect ALL runs of the module
    //          are to be added in modules.config along with scale-factor,
    //          as this is most likely to be adapted by the end user on personal taste.
    //          assembly_level for our purposes can be either 'chromosome' or 'assembled-molecule`
    //              - The first may include unlocalised units whilst the latter will not.
    blobtk_arguments = channel.of(
        [
            name: "BLOB_VIEW",
            args: "-v blob",
        ],
        [
            name: "BLOB_CHR_VIEW",
            args: "-v blob --filter assembly_level=assembled-molecule",
        ],
        [
            name: "GRID_VIEW",
            args: "-v blob --shape grid -w 0.01 -x position",
        ],
        [
            name: "GRID_CHR_VIEW",
            args: "-v blob --filter assembly_level=assembled-molecule --shape grid -w 0.01 -x position",
        ],
    )


    //
    // LOGIC: combine all the input and split back out so that we have channels * btk_args
    //
    ch_blobtk_plot_input = fasta
        .combine(btk_local_path.map { path -> [path] })
        .combine(btk_online_path.map { path -> [path] })
        .combine(blobtk_arguments)
        .multiMap { meta, path, local, online, btk_args ->
            fasta: [meta, path]
            local_path: local
            online_path: online
            args: btk_args
        }


    //
    // MODULE: Call the specified blobtk server and return grid view of the
    //          assembly position of blob on molecule
    //
    BLOBTK_PLOT(
        ch_blobtk_plot_input.fasta,
        ch_blobtk_plot_input.local_path,
        ch_blobtk_plot_input.online_path,
        ch_blobtk_plot_input.args,
        params.image_format
    )
    ch_images = BLOBTK_PLOT.out.png.mix(BLOBTK_PLOT.out.svg)

    emit:
    blobtk_images = ch_images
}
