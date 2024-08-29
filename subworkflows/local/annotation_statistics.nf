// include modules from nf-core

include { AGAT_SPSTATISTICS                  } from '../../modules/nf-core/agat/spstatistics/main'
include { AGAT_SQSTATBASIC                   } from '../../modules/nf-core/agat/sqstatbasic/main'
include { GUNZIP                             } from '../../modules/nf-core/gunzip/main'
include { EXTRACT_ANNOTATION_STATISTICS_INFO } from '../../modules/local/extract_annotation_statistics_info.nf'

workflow ANNOTATION_STATS {

    take:
    gff            //  channel: /path/to/annotation file

    main:
    ch_versions = Channel.empty()


    // Map the GFF channel to create a tuple with metadata and the file
    gff
    | map { file -> [ [ 'id': file.baseName ], file ] }
    | set {ch_gff_tupple}

    // Compress the gff files if needed
    if (params.annotation_set.endsWith('.gz')) {
        ch_unzipped = GUNZIP(ch_gff_tupple).gunzip
    } else {
        ch_unzipped = ch_gff_tupple
    }


    // Basic Annotation summary statistics
    basic_stats = AGAT_SQSTATBASIC(ch_unzipped)
    ch_versions = ch_versions.mix (basic_stats.versions.first() )


    // Other feature stats e.g intron count & length etc
    other_stats = AGAT_SPSTATISTICS(ch_unzipped)
    ch_versions = ch_versions.mix ( other_stats.versions.first() )

    // Parsing the txt files as input for the local module
    EXTRACT_ANNOTATION_STATISTICS_INFO(basic_stats.stats_txt, other_stats.stats_txt)

    emit:
    versions = ch_versions                       // channel: [ versions.yml ]

}

