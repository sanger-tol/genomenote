//
// NF-CORE MODULE IMPORT BLOCK
//
include { SAMTOOLS_FAIDX        } from '../../modules/nf-core/samtools/faidx/main'

//
// LOCAL MODULE IMPORT BLOCK
//
include { ANCESTRAL_EXTRACT     } from '../../modules/local/ancestral/extract'
include { ANCESTRAL_PLOT        } from '../../modules/local/ancestral/plot'


workflow ANNOTATION_ANCESTRAL {
    take:
    fasta      // Channel: [ meta, fasta ]
    ancestral_table      // Channel: file(ancestral_table location)
    busco_full_table     // Channel: [ meta, busco_dir ]

    main:
    ch_versions                     = Channel.empty()


    //
    // MODULE: EXTRACTS ANCESTRALLY LINKED BUSCO GENES FROM FULL TABLE
    //         THIS IS THE BUSCOPAINTER.PY SCRIPT
    //
    ANCESTRAL_EXTRACT(
        busco_full_table,
        ancestral_table
    )
    ch_versions                     = ch_versions.mix(ANCESTRAL_EXTRACT.out.versions)


    //
    // MODULE: INDEX THE INPUT ASSEMBLY
    //
    SAMTOOLS_FAIDX(
        fasta,
        [[],[]],
        false
    )
    ch_versions                     = ch_versions.mix( SAMTOOLS_FAIDX.out.versions )


    //
    // MODULE: PLOTS THE ANCESTRAL BUSCO GENES
    //         THIS IS THE PLOT_BUSCOPAINTER.PY SCRIPT
    //
    ANCESTRAL_PLOT (
        ANCESTRAL_EXTRACT.out.comp_location,
        SAMTOOLS_FAIDX.out.fai
    )
    ch_versions                     = ch_versions.mix(ANCESTRAL_PLOT.out.versions)


    emit:
    ancestral_png_plot              = ANCESTRAL_PLOT.out.png_plot
    ancestral_pdf_plot              = ANCESTRAL_PLOT.out.pdf_plot
    ancestral_complete_location     = ANCESTRAL_EXTRACT.out.comp_location
    ancestral_duplicate_location    = ANCESTRAL_EXTRACT.out.dup_location
    ancestral_summary               = ANCESTRAL_EXTRACT.out.summary
    versions                        = ch_versions                   // channel: [ versions.yml ]

}
