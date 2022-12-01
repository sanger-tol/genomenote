//
// Create genome statistics table for genome notes
//

include { NCBIDATASETS_SUMMARYGENOME as SUMMARYGENOME   } from '../../modules/local/ncbidatasets/summarygenome'
include { NCBIDATASETS_SUMMARYGENOME as SUMMARYSEQUENCE } from '../../modules/local/ncbidatasets/summarygenome'
include { GET_ODB                                       } from '../../modules/local/get_odb'
include { BUSCO                                         } from '../../modules/nf-core/busco/main'
include { MERQURYFK_MERQURYFK                           } from '../../modules/nf-core/merquryfk/merquryfk/main'
include { CREATETABLE                                   } from '../../modules/local/createtable'

workflow GENOME_STATISTICS {
    take:
    genome                 // channel: [ meta, fasta ]
    lineage_db             // channel: /path/to/buscoDB
    kmer                   // channel: [ meta, [ /path/to/kmer/kNN ] ]
    flagstat               // channel: [ meta, flagstat ]

    main:
    ch_versions = Channel.empty()

    // Genome summary statistics
    SUMMARYGENOME ( genome )
    ch_versions = ch_versions.mix(SUMMARYGENOME.out.versions.first())

    // Sequence summary statistics
    SUMMARYSEQUENCE ( genome )
    ch_versions = ch_versions.mix(SUMMARYSEQUENCE.out.versions.first())

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

    // Combined table
    ch_summary = SUMMARYGENOME.out.summary.join(SUMMARYSEQUENCE.out.summary)
    ch_busco = BUSCO.out.short_summaries_json.ifEmpty([[],[]])
    ch_merqury = MERQURYFK_MERQURYFK.out.qv.join(MERQURYFK_MERQURYFK.out.stats).ifEmpty([[],[],[]])
   
    CREATETABLE ( ch_summary, ch_busco, ch_merqury, flagstat )
    ch_versions = ch_versions.mix(CREATETABLE.out.versions.first())

    emit:
    summary  = CREATETABLE.out.csv      // channel: [ csv ]
    versions = ch_versions              // channel: [ versions.yml ]
}

process GrabFiles {
    tag "${meta.id}"
    executor 'local'

    input:
    tuple val(meta), path("in")

    output:
    tuple val(meta), path("in/*.hist"), path("in/*.ktab*", hidden:true)

    "true"
}
