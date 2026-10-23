//
// NF-CORE MODULE IMPORT BLOCK
//
include { BUSCO_BUSCO as BUSCO } from '../../../modules/nf-core/busco/busco/main'

//
// SANGER-TOL MODULE IMPORT BLOCK
//
include { ANCESTRAL_ANNOTATION } from '../../sanger-tol/ancestral_annotation/main'


workflow ANNOTATION_ANCESTRAL {
    take:
    fasta // Channel: [ meta, fasta ]
    ancestral_table // Channel: file(ancestral_table location)
    val_ancestral_lineage // ancestral lineage value to use for BUSCO, e.g. lepidoptera_odb10
    busco_db // Channel:

    main:
    ch_versions = channel.empty()

    //
    // MODULE: RUN BUSCO SOLELY FOR ANCESTRAL NOW THAT THE TWO CAN USE
    //          DIFFERING ODB VERSIONS
    //
    BUSCO(
        fasta,
        "genome",
        val_ancestral_lineage,
        busco_db.ifEmpty([]),
        [],
        false,
    )
    ch_versions = ch_versions.mix(BUSCO.out.versions.first())


    //
    // MODULE: EXTRACTS ANCESTRALLY LINKED BUSCO GENES FROM FULL TABLE
    //         THIS IS THE BUSCOPAINTER.PY SCRIPT
    //
    busco_table_meta_mod = BUSCO.out.full_table
        .combine(ancestral_table)
        .map { meta, table, ancestral_meta, ancestral_file ->
            [meta + [lineage: val_ancestral_lineage, ancestral_table: ancestral_meta.id], table, ancestral_meta, ancestral_file]
        }
        .multiMap { meta, table, ancestral_meta, ancestral_file ->
            table: tuple(meta, table)
            ancestral_table: tuple(ancestral_meta, ancestral_file)
        }

    ANCESTRAL_ANNOTATION(
        fasta,
        busco_table_meta_mod.ancestral_table,
        busco_table_meta_mod.table,
    )

    emit:
    ancestral_png_plot           = ANCESTRAL_ANNOTATION.out.ancestral_png_plot // channel: [   [id], file  ]
    ancestral_pdf_plot           = ANCESTRAL_ANNOTATION.out.ancestral_pdf_plot // channel: [   [id], file  ]
    ancestral_complete_location  = ANCESTRAL_ANNOTATION.out.ancestral_complete_location // channel: [   [id], file  ]
    ancestral_duplicate_location = ANCESTRAL_ANNOTATION.out.ancestral_duplicate_location // channel: [   [id], file  ]
    ancestral_summary            = ANCESTRAL_ANNOTATION.out.ancestral_summary // channel: [   [id], file  ]
    versions                     = ch_versions // channel: [ versions.yml  ]
}
