//
// Create genome statistics table for genome notes
//

include { NCBIDATASETS_SUMMARYGENOME as SUMMARYGENOME   } from '../../modules/local/ncbidatasets/summarygenome'
include { NCBIDATASETS_SUMMARYGENOME as SUMMARYSEQUENCE } from '../../modules/local/ncbidatasets/summarygenome'
include { GET_ODB                                       } from '../../modules/local/get_odb'
include { BUSCO                                         } from '../../modules/nf-core/busco/main'
include { FASTK_FASTK                                   } from '../../modules/nf-core/fastk/fastk/main'
include { MERQURYFK_MERQURYFK                           } from '../../modules/nf-core/merquryfk/merquryfk/main'
include { CREATETABLE                                   } from '../../modules/local/createtable'


workflow GENOME_STATISTICS {
    take:
    genome                 // channel: [ meta, fasta ]
    lineage_db             // channel: /path/to/buscoDB
    pacbio                 // channel: [ meta, kmer_db or reads ]
    flagstat               // channel: [ meta, flagstat ]


    main:
    ch_versions = Channel.empty()


    // Genome summary statistics
    SUMMARYGENOME ( genome )
    ch_versions = ch_versions.mix ( SUMMARYGENOME.out.versions.first() )


    // Sequence summary statistics
    SUMMARYSEQUENCE ( genome )
    ch_versions = ch_versions.mix ( SUMMARYSEQUENCE.out.versions.first() )


    // Get ODB lineage value
    GET_ODB ( genome )
    ch_versions = ch_versions.mix ( GET_ODB.out.versions.first() )


    // BUSCO
    GET_ODB.out.csv
    | splitCsv()
    | map { row -> row[1] }
    | set { ch_lineage }
    
    BUSCO ( genome, ch_lineage, lineage_db, [] )
    ch_versions = ch_versions.mix ( BUSCO.out.versions.first() )


    // FastK
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


    // Define channel for MERQURKFK
    FASTK_FASTK.out.hist
    | join ( FASTK_FASTK.out.ktab )
    | set { ch_combo }
    
    ch_grab = GrabFiles ( ch_pacbio.dir )
    
    ch_combo
    | mix ( ch_grab )
    | combine ( genome )
    | map { meta, hist, ktab, meta2, fasta -> [ meta, hist, ktab, fasta, [] ] }
    | set { ch_merq }


    // MerquryFK
    MERQURYFK_MERQURYFK ( ch_merq )
    ch_versions = ch_versions.mix ( MERQURYFK_MERQURYFK.out.versions.first() )


    // Combined table
    SUMMARYGENOME.out.summary
    | join ( SUMMARYSEQUENCE.out.summary )
    | set { ch_summary }
    
    BUSCO.out.short_summaries_json
    | ifEmpty ( [ [], [] ] )
    | set { ch_busco }
    
    MERQURYFK_MERQURYFK.out.qv
    | join ( MERQURYFK_MERQURYFK.out.stats )
    | ifEmpty ( [ [], [], [] ] )
    | set { ch_merqury }

    CREATETABLE ( ch_summary, ch_busco, ch_merqury, flagstat )
    ch_versions = ch_versions.mix ( CREATETABLE.out.versions.first() )


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
