//
// NF-CORE MODULE IMPORT BLOCK
//
include { SAMTOOLS_FAIDX        } from '../../../modules/nf-core/samtools/faidx/main'
include { BUSCO_BUSCO as BUSCO  } from '../../../modules/nf-core/busco/busco/main'

//
// LOCAL MODULE IMPORT BLOCK
//
include { ANCESTRAL_EXTRACT     } from '../../../modules/sanger-tol/ancestral/extract'
include { ANCESTRAL_PLOT        } from '../../../modules/sanger-tol/ancestral/plot'


workflow ANNOTATION_ANCESTRAL {
    take:
    fasta                // Channel: [ meta, fasta ]
    ancestral_table      // Channel: file(ancestral_table location)
    ch_ancestral_lineage // Channel:
    lineage_db           // Channel:


    main:
    ch_versions                     = Channel.empty()


    //
    // MODULE: RUN BUSCO SOLELY FOR ANCESTRAL NOW THAT THE TWO CAN USE
    //          DIFFERING ODB VERSIONS
    //
    BUSCO (
        fasta,
        "genome",
        ch_ancestral_lineage,
        lineage_db.ifEmpty([]),
        [],
        false
    )
    ch_versions         = ch_versions.mix ( BUSCO.out.versions.first() )


    //
    // MODULE: EXTRACTS ANCESTRALLY LINKED BUSCO GENES FROM FULL TABLE
    //         THIS IS THE BUSCOPAINTER.PY SCRIPT
    //
    ANCESTRAL_EXTRACT(
        BUSCO.out.full_table,
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
    ancestral_png_plot              = ANCESTRAL_PLOT.out.png_plot           // channel: [   [id], file  ]
    ancestral_pdf_plot              = ANCESTRAL_PLOT.out.pdf_plot           // channel: [   [id], file  ]
    ancestral_complete_location     = ANCESTRAL_EXTRACT.out.comp_location   // channel: [   [id], file  ]
    ancestral_duplicate_location    = ANCESTRAL_EXTRACT.out.dup_location    // channel: [   [id], file  ]
    ancestral_summary               = ANCESTRAL_EXTRACT.out.summary         // channel: [   [id], file  ]
    versions                        = ch_versions                           // channel: [ versions.yml  ]

}
