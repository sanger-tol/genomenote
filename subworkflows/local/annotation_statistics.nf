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
    AGAT_SQSTATBASIC(ch_unzipped)
    ch_versions = ch_versions.mix ( AGAT_SQSTATBASIC.out.versions.first() )

    // View the outputs from the subworkflow
    AGAT_SQSTATBASIC.out.stats_txt.view { file ->
        println "Stats file: $file"
    }

    AGAT_SQSTATBASIC.out.versions.view { file ->
        println "Versions file: $file"
    }

    // Other feature stats e.g intron count & length etc
    AGAT_SPSTATISTICS(ch_unzipped)
    ch_versions = ch_versions.mix ( AGAT_SPSTATISTICS.out.versions.first() )

    // View the outputs from the subworkflow
    AGAT_SPSTATISTICS.out.stats_txt.view { file ->
        println "Stats file: $file"
    }

    AGAT_SPSTATISTICS.out.versions.view { file ->
        println "Versions file: $file"
    }

    // Create tuples with metadata and file paths
    ch_basic_stats = AGAT_SQSTATBASIC.out.stats_txt.map { [id: it[0], path: it[1]] }
    ch_other_stats = AGAT_SPSTATISTICS.out.stats_txt.map { [id: it[0], path: it[1]] }

    // Parsing the txt files as input for the local module
    EXTRACT_ANNOTATION_STATISTICS_INFO(ch_basic_stats, ch_other_stats)
    ch_versions = ch_versions.mix( EXTRACT_ANNOTATION_STATISTICS_INFO.out.versions.first() )

    emit:
    stats   = EXTRACT_ANNOTATION_STATISTICS_INFO.out.csv  // channel: [ csv ]
    versions = ch_versions                       // channel: [ versions.yml ]

}

