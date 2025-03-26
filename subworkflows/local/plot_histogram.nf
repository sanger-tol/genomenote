include { CAT_CAT                     } from '../modules/nf-core/cat_cat/main'
include { GENESCOPEFK                } from '../modules/nf-core/genomescope2/main'

workflow PLOT_HISTOGRAM {
    take:
    ch_list_reads

    main:

    // potentially need to merge channels depending on creation

    //
    // MODULE: CONCATENATE THE READS INTO A SINGLE FILE
    //
    CAT_CAT ( ch_list_reads)
    ch_versions         = ch_versions.mix(CAT_CAT.out.versions)

    // apprently naming of the output may need to be corrected here or at least pinned for control.

    //
    // MODULE: FASTK to calculate hist data for genescope
    //
    FASTK_FASTK( CAT_CAT.out.outfile )
    ch_versions         = ch_versions.mix(FASTK_FASTK.out.versions)


    //
    // MODULE: HISTEX generates a histogram in -h given intervals
    //
    FASTK_HISTEX( FASTK_FASTK.out.hist )
    ch_versions         = ch_versions.mix(FASTK_HISTEX.out.versions)


    //
    // MODULE: GENESCOPEFK PLOT THE KMER HISTOGRAM and
    //          outputs a correct estimate of genome size and % repetitiveness
    //
    GENESCOPEFK( FASTK_HISTEX.out.hist )
    ch_versions         = ch_versions.mix(GENESCOPEFK.out.versions)


    emit:
    ch_genome_size      = GENESCOPEFK.out.genome_size
    ch_repetitiveness   = GENESCOPEFK.out.repetitiveness
    ch_linear_plot      = GENESCOPEFK.out.linear_plot
    ch_log_plot         = GENESCOPEFK.out.log_plot
    ch_model            = GENESCOPEFK.out.model
    ch_summary          = GENESCOPEFK.out.summary
    ch_trans_lin_plot   = GENESCOPEFK.out.transformed_linear_plot
    ch_trans_log_plot   = GENESCOPEFK.out.transformed_log_plot
    ch_versions

}
