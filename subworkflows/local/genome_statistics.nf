//
// Create genome statistics table for genome notes
//

include { GOAT_NFIFTY         } from '../../modules/local/goat_nfifty'
include { GET_ODB             } from '../../modules/local/get_odb'
include { BUSCO               } from '../../modules/nf-core/modules/busco/main'
include { CREATE_TABLE        } from '../../modules/local/create_table'

workflow GENOME_STATISTICS {
    take:
    genome
    lineage_db
    kmer

    main:
    ch_versions = Channel.empty()

    // Contig and scaffold N50
    GOAT_NFIFTY ( genome )
    ch_versions = ch_versions.mix(GOAT_NFIFTY.out.versions)

    // Get ODB lineage value
    GET_ODB ( genome )
    ch_versions = ch_versions.mix(GET_ODB.out.versions)

    GET_ODB.out.csv
    .splitCsv()
    .map { row -> row[1] }
    .set { ch_lineage }

    // BUSCO
    BUSCO ( genome, ch_lineage, lineage_db, [] )
    ch_versions = ch_versions.mix(BUSCO.out.versions)

    // Combine results
    ct = GOAT_NFIFTY.out.json.join(BUSCO.out.short_summaries_json, by: [0])

    CREATE_TABLE ( ct )
    ch_versions = ch_versions.mix(CREATE_TABLE.out.versions)

    emit:
    table    = CREATE_TABLE.out.csv     // channel: [ csv ]
    versions = ch_versions              // channel: [ versions.yml ]
}
