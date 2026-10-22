include { BLOBTK_PLOT } from '../../../modules/nf-core/blobtk/plot/main'


workflow GET_BLOBTK_PLOTS {

    take:
    ch_fasta                    // channel: [meta], path/to/fasta
    ch_btk_local_path           // channel: [path/to/dir]
    ch_btk_online_path          // channel: https://online.repository_of_btk.datasets
    ch_blobtk_output_format     // channel: "png" or "svg"

    main:

    //
    // NOTE: other arguments for this module, that effect ALL runs of the module
    //          are to be added in modules.config along with scale-factor,
    //          as this is most likely to be adapted by the end user on personal taste.
    //          assembly_level for our purposes can be either 'chromosome' or 'assembled-molecule`
    //              - The first may include unlocalised units whilst the latter will not.
    blobtk_arguments    = channel.of(
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
            name: "GRID_CHR_VIEW",
            args: "-v blob --filter assembly_level=assembled-molecule --shape grid -w 0.01 -x position"
        ],
        [
            name: "SNAIL_PLOT",
            args: "-v snail"
        ]
    )


    //
    // LOGIC: combine all the input and split back out so that we have channels * btk_args
    //
    ch_blobtk_plot_input = ch_fasta
        .combine(ch_btk_local_path.map{ btk_dir -> [btk_dir] })
        .combine(ch_btk_online_path.map{ btk_url -> [btk_url] })
        .combine(blobtk_arguments)
        .combine(ch_blobtk_output_format)
        .multiMap { meta, ref, local, online, btk_args, output_format ->
            fasta: [meta, ref]
            local_path: local
            online_path: online
            args: btk_args
            format: output_format
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
        ch_blobtk_plot_input.format
    )

    png_channel             = channel.empty()
    ch_png_images           = png_channel.mix(BLOBTK_PLOT.out.png)

    svg_channel             = channel.empty()
    ch_svg_images           = svg_channel.mix(BLOBTK_PLOT.out.svg)

    emit:
    png_blobtk_images       = ch_png_images
    svg_blobtk_images       = ch_svg_images
}
