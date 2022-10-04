//
// Create genome statistics table for genome notes
//

include { GOAT_NFIFTY         } from '../../modules/local/goat_nfifty'
include { GET_ODB             } from '../../modules/local/get_odb'
include { BUSCO               } from '../../modules/nf-core/modules/busco/main'
include { MERQURYFK_MERQURYFK } from '../../modules/nf-core/modules/merquryfk/merquryfk/main'
include { CREATE_TABLE        } from '../../modules/local/create_table'

workflow GENOME_STATISTICS {
    take:
    genome                 // channel: [ meta, fasta ]
    lineage_db             // channel: /path/to/buscoDB
    kmer                   // channel: [ [ meta ], [ /path/to/kmer/kNN ] ]

    main:
    ch_versions = Channel.empty()

    // Contig and scaffold N50
    GOAT_NFIFTY ( genome )
    ch_versions = ch_versions.mix(GOAT_NFIFTY.out.versions.first())

    // Get ODB lineage value
    GET_ODB ( genome )
    ch_versions = ch_versions.mix(GET_ODB.out.versions.first())

    // BUSCO
    ch_lineage = GET_ODB.out.csv.splitCsv().map { row -> row[1] }
    BUSCO ( genome, ch_lineage, lineage_db, [] )
    ch_versions = ch_versions.mix(BUSCO.out.versions.first())

    // MerquryFK
    ch_merq = GrabFiles(kmer).combine(genome).map { meta, hist, ktab, meta2, fasta -> [ meta, hist, ktab, fasta ] }
    MERQURYFK_MERQURYFK ( ch_merq )
    ch_versions = ch_versions.mix(MERQURYFK_MERQURYFK.out.versions.first())

    // Combine results
    ct1 = GOAT_NFIFTY.out.json.join( BUSCO.out.short_summaries_json )
    ct2 = MERQURYFK_MERQURYFK.out.qv.join( MERQURYFK_MERQURYFK.out.stats )
    ct  = ct1.combine( ct2 ).map { meta, n50, busco, meta2, qv, stats -> [ [id: meta.id, datatype: meta2.datatype, outdir: meta.outdir], n50, busco, qv, stats ] }
    CREATE_TABLE ( ct )
    ch_versions = ch_versions.mix(CREATE_TABLE.out.versions.first())

    emit:
    table    = CREATE_TABLE.out.csv     // channel: [ csv ]
    versions = ch_versions              // channel: [ versions.yml ]
}

process GrabFiles {
    executor 'local'

    input:
    tuple val(meta), path("in")

    output:
    tuple val(meta), path("in/*.hist"), path("in/*.ktab*", hidden:true)

    "true"
}
