//
// Create ancestral linkage plots against input assembly
//
include { SAMTOOLS_FAIDX        } from '../../../modules/nf-core/samtools/faidx/main'
include { ANCESTRAL_EXTRACT     } from '../../../modules/sanger-tol/ancestral/extract'
include { ANCESTRAL_PLOT        } from '../../../modules/sanger-tol/ancestral/plot'


workflow ANCESTRAL_ANNOTATION {
    take:
    reference            // Channel: [ meta, reference ]
    ancestral_table      // Channel: [ meta, ancestral_table ]
    busco_full_table     // Channel: [ meta, busco_dir ]

    main:
    //
    // MODULE: EXTRACTS ANCESTRALLY LINKED BUSCO GENES FROM FULL TABLE
    //
    ANCESTRAL_EXTRACT(
        busco_full_table,
        ancestral_table
    )

    //
    // MODULE: INDEX THE INPUT ASSEMBLY
    //
    SAMTOOLS_FAIDX(
        reference.map { meta, assembly -> [meta, assembly, []] },
        false
    )

    //
    // MODULE: PLOTS THE ANCESTRAL BUSCO GENES
    //
    ANCESTRAL_PLOT (
        ANCESTRAL_EXTRACT.out.comp_location,
        SAMTOOLS_FAIDX.out.fai
    )

    emit:
    ancestral_png_plot              = ANCESTRAL_PLOT.out.png_plot           // channel: [   [id], file  ]
    ancestral_pdf_plot              = ANCESTRAL_PLOT.out.pdf_plot           // channel: [   [id], file  ]
    ancestral_complete_location     = ANCESTRAL_EXTRACT.out.comp_location   // channel: [   [id], file  ]
    ancestral_duplicate_location    = ANCESTRAL_EXTRACT.out.dup_location    // channel: [   [id], file  ]
    ancestral_summary               = ANCESTRAL_EXTRACT.out.summary         // channel: [   [id], file  ]
}
