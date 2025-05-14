// include modules from nf-core

include { AGAT_SPSTATISTICS                             } from '../../modules/nf-core/agat/spstatistics/main'
include { AGAT_SQSTATBASIC                              } from '../../modules/nf-core/agat/sqstatbasic/main'
include { GUNZIP                                        } from '../../modules/nf-core/gunzip/main'
include { EXTRACT_ANNOTATION_STATISTICS_INFO            } from '../../modules/local/extract_annotation_statistics_info.nf'
include { BUSCO_BUSCO as BUSCOPROTEINS                  } from '../../modules/nf-core/busco/busco/main'
include { GFFREAD                                       } from '../../modules/nf-core/gffread/main'

workflow ANNOTATION_STATISTICS {

    take:
    gff                    //  channel: /path/to/annotation file
    genome                 // channel: [ meta, fasta ]
    busco_lineage          // channel: lineage_name
    lineage_db             // channel: /path/to/buscoDB

    main:
    ch_versions = Channel.empty()

    // Map the GFF channel to create a tuple with metadata and the file
    gff
    | map { file ->
        [ [ 'id': params.assembly + '_annotation', 'ext': "gff", 'filename': file.baseName ], file ]
    }
    | set { ch_gff_tupple }

    // Uncompress the gff files if needed
    if (params.annotation_set.endsWith('.gz')) {
        ch_gff_unzipped = GUNZIP(ch_gff_tupple).gunzip
        ch_versions = ch_versions.mix ( GUNZIP.out.versions.first() )
    } else {
        ch_gff_unzipped = ch_gff_tupple
    }

    // Basic Annotation summary statistics
    AGAT_SQSTATBASIC(ch_gff_unzipped)
    ch_versions = ch_versions.mix ( AGAT_SQSTATBASIC.out.versions.first() )

    // Other annotation statistics
    AGAT_SPSTATISTICS(ch_gff_unzipped)
    ch_versions = ch_versions.mix ( AGAT_SPSTATISTICS.out.versions.first() )

    genome
    | map { meta, fasta -> fasta }
    | set { ch_fasta }

    // Obtaining the protein fasta file from the gff3
    GFFREAD(ch_gff_unzipped, ch_fasta)
    ch_versions = ch_versions.mix ( GFFREAD.out.versions.first() )

    // Running BUSCO in protein mode
    BUSCOPROTEINS(GFFREAD.out.gffread_fasta, 'proteins', busco_lineage, lineage_db.ifEmpty([]), [] )
    ch_versions = ch_versions.mix ( BUSCOPROTEINS.out.versions.first() )

    // Parsing the stats_txt files as input channels
    EXTRACT_ANNOTATION_STATISTICS_INFO(
        AGAT_SQSTATBASIC.out.stats_txt,
        AGAT_SPSTATISTICS.out.stats_txt,
        BUSCOPROTEINS.out.short_summaries_json
    )

    ch_versions = ch_versions.mix( EXTRACT_ANNOTATION_STATISTICS_INFO.out.versions.first() )

    emit:
    summary   = EXTRACT_ANNOTATION_STATISTICS_INFO.out.csv  // channel: [ csv ]
    versions = ch_versions                       // channel: [ versions.yml ]

}

