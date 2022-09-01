//
// Create genome statistics table for genome notes
//

include { GOAT_NFIFTY         } from '../../modules/local/goat_nfifty'
include { CREATE_TABLE        } from '../../modules/local/create_table'

workflow GENOME_STATISTICS {
    take:
    genome
    kmer

    main:
    ch_versions = Channel.empty()

    // Contig and scaffold N50
    genome
        .flatten()
        .map { file  -> file.baseName.replaceFirst(/.unmasked/, "").replaceFirst(/.subset/, "") }
        .set { asm }

    GOAT_NFIFTY ( asm )
    ch_versions = ch_versions.mix(GOAT_NFIFTY.out.versions)

    // Combine results
    ct = GOAT_NFIFTY.out.json.toList()

    CREATE_TABLE ( ct )
    ch_versions = ch_versions.mix(CREATE_TABLE.out.versions)

    emit:
    table    = CREATE_TABLE.out.csv     // channel: [ csv ]
    versions = ch_versions              // channel: [ versions.yml ]
}
