//
// Create genome statistics table for genome notes
//

include { NCBIDATASETS_SUMMARYGENOME as SUMMARYGENOME   } from '../../modules/local/ncbidatasets/summarygenome'
include { NCBIDATASETS_SUMMARYGENOME as SUMMARYSEQUENCE } from '../../modules/local/ncbidatasets/summarygenome'
include { NCBI_GET_ODB                                  } from '../../modules/local/ncbidatasets/get_odb'
include { BUSCO_BUSCO as BUSCO                          } from '../../modules/nf-core/busco/busco/main'
include { RESTRUCTUREBUSCODIR                           } from '../../modules/local/restructurebuscodir'
include { FASTK_FASTK                                   } from '../../modules/nf-core/fastk/fastk/main'
include { CREATETABLE                                   } from '../../modules/local/createtable'
include { GFASTATS                                      } from '../../modules/nf-core/gfastats/main'

// This is only temporarily removed so I'm leaving it here for now
//include { MERQURYFK_MERQURYFK                           } from '../../modules/nf-core/merquryfk/merquryfk/main'

workflow GENOME_STATISTICS {
    take:
    genome                 // channel: [ meta, fasta ]
    lineage_tax_ids        // channel: /path/to/lineage_tax_ids
    lineage_db             // channel: /path/to/buscoDB
    pacbio                 // channel: [ meta, kmer_db or reads ]
    flagstat               // channel: [ meta, flagstat ]


    main:
    ch_versions = Channel.empty()


    //
    // MODULE: Genome summary statistics
    //
    SUMMARYGENOME ( genome )
    ch_versions = ch_versions.mix ( SUMMARYGENOME.out.versions.first() )


    //
    // MODULE: Get genomic assembly statistics using GFASTATS
    //
    GFASTATS(
        genome,
        "",
        "",
        "",
        [[],[]],
        [[],[]],
        [[],[]],
        [[],[]]
    )
    ch_versions     = ch_versions.mix( GFASTATS.out.versions )


    //
    // MODULE: Sequence summary statistics
    //
    SUMMARYSEQUENCE ( genome )
    ch_versions = ch_versions.mix ( SUMMARYSEQUENCE.out.versions.first() )


    //
    // MODULE: Get ODB lineage value
    //
    NCBI_GET_ODB ( SUMMARYGENOME.out.summary, lineage_tax_ids )
    ch_versions = ch_versions.mix ( NCBI_GET_ODB.out.versions.first() )


    //
    // MODULE: BUSCO
    //
    NCBI_GET_ODB.out.csv
    | map { meta, csv -> csv }
    | splitCsv()
    | map { row -> row[1] }
    | set { ch_lineage }

    BUSCO ( genome, "genome", ch_lineage, lineage_db.ifEmpty([]), [] )
    ch_versions = ch_versions.mix ( BUSCO.out.versions.first() )


    //
    // MODULE: Tidy up the BUSCO output directories before publication
    //
    RESTRUCTUREBUSCODIR(
        BUSCO.out.batch_summary
        | combine ( ch_lineage )
        | join ( BUSCO.out.short_summaries_txt, remainder: true )
        | join ( BUSCO.out.short_summaries_json, remainder: true )
        | join ( BUSCO.out.busco_dir )
        | map { meta, batch_summary, lineage, short_summaries_txt, short_summaries_json, busco_dir -> [meta, lineage, batch_summary, short_summaries_txt ?: [], short_summaries_json ?: [], busco_dir] }
    )
    ch_versions = ch_versions.mix ( RESTRUCTUREBUSCODIR.out.versions.first() )


    //
    // MODULE: FastK
    //
    pacbio
    | branch {
        meta, file ->
            dir: file.isDirectory()
            file: true
    }
    | set { ch_pacbio }

    ch_pacbio.file
    | map { meta, bam -> [ meta + [ id: meta.id.split('_')[0..-2].join('_') ], bam ] }
    | groupTuple ( by: [0] )
    | set { ch_fastk }

    FASTK_FASTK ( ch_fastk )
    ch_versions = ch_versions.mix ( FASTK_FASTK.out.versions.first() )


    //
    // MODULE: Define channel for MERQURKFK
    //
    FASTK_FASTK.out.hist
    | join ( FASTK_FASTK.out.ktab )
    | set { ch_combo }

    ch_pacbio.dir
    | map { meta, dir -> [
        meta,
        dir.listFiles().findAll { it.toString().endsWith(".hist") } .collect(),
        dir.listFiles().findAll { it.toString().contains(".ktab") } .collect(),
    ] }
    | set { ch_grab }

    ch_combo
    | mix ( ch_grab )
    | combine ( genome )
    | map { meta, hist, ktab, meta2, fasta -> [ meta + [genome_size: meta2.genome_size], hist, ktab, fasta, [] ] }
    | set { ch_merq }


    // This is only temporarily removed so I'm leaving it here for now
    // // MerquryFK
    // MERQURYFK_MERQURYFK ( ch_merq, [], [] )
    // ch_versions = ch_versions.mix ( MERQURYFK_MERQURYFK.out.versions.first() )


    //
    // MODULE: Combined table
    //
    SUMMARYGENOME.out.summary
    | join ( SUMMARYSEQUENCE.out.summary )
    | set { ch_summary }

    BUSCO.out.short_summaries_json
    | ifEmpty ( [ [], [] ] )
    | set { ch_busco }

    // This is only temporarily removed so I'm leaving it here for now
    // MERQURYFK_MERQURYFK.out.qv
    // | join ( MERQURYFK_MERQURYFK.out.stats )
    // | map { meta, qv, comp -> [ meta + [ id: "merq" ], qv, comp ] }
    // | groupTuple ()
    // | ifEmpty ( [ [], [], [] ] )
    // | set { ch_merqury }

    flagstat
    // Queue channel of tuple(meta, file)
    | toList
    // Value channel of list(tuple(meta, file))
    | map { lmf -> [
            lmf.collect { it[0] },
            lmf.collect { it[1] },
        ] }
    // Now channel of tuple(list(meta), list(file))
    | set { ch_flagstat }


    //
    // MODULE: CREATETABLE ( ch_summary, ch_busco, ch_merqury, ch_flagstat )
    //
    CREATETABLE ( ch_summary, ch_busco, [[], [], []], ch_flagstat )
    ch_versions = ch_versions.mix ( CREATETABLE.out.versions.first() )


    //
    // MODULE: BUSCO results for MULTIQC
    //
    BUSCO.out.short_summaries_txt
    | ifEmpty ( [ [], [] ] )
    | set { multiqc }


    emit:
    summary_seq = SUMMARYSEQUENCE.out.summary   // channel: [ meta, summary ]
    summary  = CREATETABLE.out.csv      // channel: [ csv ]
    multiqc                             // channel: [ meta, summary ]
    versions = ch_versions              // channel: [ versions.yml ]

}

