//
// NF-CORE MODULE IMPORT BLOCK
//
include { BUSCO_BUSCO                   } from '../../modules/nf-core/busco/busco/main'

//
// LOCAL MODULE IMPORT BLOCK
//
include { ANCESTRAL_EXTRACT             } from '../../modules/local/ancestral/extract'
include { ANCESTRAL_PLOT                } from '../../modules/local/ancestral/plot'


workflow BUSCO_ANNOTATION {
    //
    // NOTE: THIS IS THE WORKFLOW PULLED IN THE PIPELINE PRIOR TO OPTIMISATION
    //

    take:
    dot_genome           // Channel: tuple [val(meta), [ datafile ]]
    reference_tuple      // Channel: tuple [val(meta), [ datafile ]]
    lineage_odb          // Channel: val(lineage_db)
    lineage_db_path      // Channel: val(/path/to/buscoDB)
    buscogene_as         // Channel: val(dot_as location)
    ancestral_table      // Channel: val(ancestral_table location)

    main:
    ch_versions                 = Channel.empty()


    //
    // MODULE: RUN BUSCO TO OBTAIN FULL_TABLE.CSV
    //         EMITS FULL_TABLE.CSV
    //
    BUSCO_BUSCO (
        reference_tuple,
        "genome",
        lineage_odb,
        lineage_db_path,
        []
    )
    ch_versions                 = ch_versions.mix(BUSCO_BUSCO.out.versions.first())
    ch_busco_grab               = GrabFiles(BUSCO_BUSCO.out.busco_dir)


    //
    // LOGIC: AGGREGATE DATA AND SORT BRANCH ON CLASS
    //         FORCES PROCESSES TO ONLY RUN WHEN CONSTRAINT IS MET
    //         LOGIC WOULD HAVE TO BE UPDATED ONCE THE NUMBER OF THESE START GROWING.
    //         THIS NEEDS TO BE MOVED INTO THE MAIN WORKFLOW
    //
    lineageinfo
        .combine(BUSCO_BUSCO.out.busco_dir)
        .combine(ancestral_table)
        .branch {
            lep:     it[0].split('_')[0] == "lepidoptera"
            general: true
        }
        .set{ ch_busco_data }


    //
    // MODULE: EXTRACTS ANCESTRALLY LINKED BUSCO GENES FROM FULL TABLE
    //         THIS IS THE BUSCOPAINTER.PY SCRIPT
    //
    ch_busco_grab           = GrabFiles(busco_dir)

    ANCESTRAL_EXTRACT(
        ch_busco_grab,
        ancestral_table
    )
    ch_versions             = ch_versions.mix(ANCESTRAL_EXTRACT.out.versions)


    //
    // MODULE: PLOTS THE ANCESTRAL BUSCO GENES
    //         THIS IS THE PLOT_BUSCOPAINTER.PY SCRIPT
    //
    // ANCESTRAL_PLOT (
    //     ANCESTRAL_EXTRACT.out.comp_location,
    //     ANCESTRAL_EXTRACT.out.dup_location,
    //     ANCESTRAL_EXTRACT.out.summary,
    //     genome_index
    // )
    // ch_versions             = ch_versions.mix(ANCESTRAL_PLOT.out.versions)


    emit:
    busco_genome_outdir             = BUSCO_BUSCO.out.busco_dir
    ancestral_plot                  = ANCESTRAL_PLOT.out.merian_plot
    ancestral_complete_location     = ANCESTRAL_EXTRACT.out.comp_location,
    ancestral_duplicate_location    = ANCESTRAL_EXTRACT.out.dup_location,
    ancestral_summary               = ANCESTRAL_EXTRACT.out.summary

}

process GrabFiles {
    label 'process_tiny'

    tag "${meta.id}"
    executor 'local'

    input:
    tuple val(meta), path("in")

    output:
    tuple val(meta), path("in/*/*/full_table.tsv")

    "true"
}
