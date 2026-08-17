//
// NF-CORE MODULE IMPORT BLOCK
//
include { BUSCO_BUSCO as BUSCO } from '../../../modules/nf-core/busco/busco/main'

//
// LOCAL MODULE IMPORT BLOCK
//
include { ANCESTRAL_EXTRACT    } from '../../../modules/sanger-tol/ancestral/extract'
include { ANCESTRAL_PLOT       } from '../../../modules/sanger-tol/ancestral/plot'


workflow ANNOTATION_ANCESTRAL {
    take:
    fasta // Channel: [ meta, fasta, fai ]
    ancestral_table // Channel: file(ancestral_table location)
    val_ancestral_lineage // ancestral lineage value to use for BUSCO, e.g. lepidoptera_odb10
    busco_db // Channel:

    main:
    ch_versions = channel.empty()

    // LOGIG: BUSCO only needs the Fasta file, while the rest of the sub-workflow only needs the .fai
    ch_fasta = fasta.multiMap { meta, fa, fai ->
        fasta: tuple(meta, fa)
        fai: tuple(meta, fai)
    }

    //
    // MODULE: RUN BUSCO SOLELY FOR ANCESTRAL NOW THAT THE TWO CAN USE
    //          DIFFERING ODB VERSIONS
    //
    BUSCO(
        ch_fasta.fasta,
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
        .join(ch_fasta.fai)
        .combine(ancestral_table)
        .map { meta, table, fai, ancestral_meta, ancestral_file ->
            [meta + [lineage: val_ancestral_lineage, ancestral_table: ancestral_meta.id], table, fai, ancestral_meta, ancestral_file]
        }
        .multiMap { meta, table, fai, ancestral_meta, ancestral_file ->
            table: tuple(meta, table)
            ancestral_table: tuple(ancestral_meta, ancestral_file)
            fai: tuple(meta, fai)
        }

    ANCESTRAL_EXTRACT(
        busco_table_meta_mod.table,
        busco_table_meta_mod.ancestral_table,
    )
    ch_versions = ch_versions.mix(ANCESTRAL_EXTRACT.out.versions)


    ch_ancestral_plot = ANCESTRAL_EXTRACT.out.comp_location
        .join(busco_table_meta_mod.fai)
        .multiMap { meta, comp_location, fai ->
            comp_location: tuple(meta, comp_location)
            fai: tuple(meta, fai)
        }


    //
    // MODULE: PLOTS THE ANCESTRAL BUSCO GENES
    //         THIS IS THE PLOT_BUSCOPAINTER.PY SCRIPT
    //
    ANCESTRAL_PLOT(
        ch_ancestral_plot.comp_location,
        ch_ancestral_plot.fai,
    )
    ch_versions = ch_versions.mix(ANCESTRAL_PLOT.out.versions)

    emit:
    ancestral_png_plot           = ANCESTRAL_PLOT.out.png_plot // channel: [   [id], file  ]
    ancestral_pdf_plot           = ANCESTRAL_PLOT.out.pdf_plot // channel: [   [id], file  ]
    ancestral_complete_location  = ANCESTRAL_EXTRACT.out.comp_location // channel: [   [id], file  ]
    ancestral_duplicate_location = ANCESTRAL_EXTRACT.out.dup_location // channel: [   [id], file  ]
    ancestral_summary            = ANCESTRAL_EXTRACT.out.summary // channel: [   [id], file  ]
    versions                     = ch_versions // channel: [ versions.yml  ]
}
