#!/usr/bin/env nextflow

//
// Combine output to produce genome note doc and optionally write data back to genome dates database
//
include { PARSE_METADATA                    }       from '../../modules/local/parse_metadata'
include { COMBINE_STATISTICS_AND_METADATA   }       from '../../modules/local/combine_statistics_and_metadata'
include { POPULATE_TEMPLATE                 }       from '../../modules/local/populate_template'
include { WRITE_TO_GENOME_NOTES_DB          }       from '../../modules/local/write_to_database'

workflow COMBINE_NOTE_DATA {
    take:
    ch_params // channel: /path/to/csv/file/consistent_parameters from GENOME_METADATA subworkflow
    ch_summary // channel: /path/to/csv/summary/file from GENOME_STATISTICS subworkflow 
    ch_note_template   // channel: /path/to/genome_note_doc_template


    main:
    ch_versions = Channel.empty()

    ch_summary 
    | map {  meta, it ->
        meta.ext = "csv"
        meta.source = "genome"
        meta.type = "summary"
        [ meta, it ]
    }
    | set { ch_summary_meta }

    PARSE_METADATA(ch_summary_meta)
    ch_versions = ch_versions.mix( PARSE_METADATA.out.versions.first() )



    COMBINE_STATISTICS_AND_METADATA(ch_params, PARSE_METADATA.out.file_path)
    ch_versions = ch_versions.mix( COMBINE_STATISTICS_AND_METADATA.out.versions.first() )

    COMBINE_STATISTICS_AND_METADATA.out.consistent
    | multiMap { it ->
        TEMPLATE: it
        DB: it
    }
    | set { ch_params_consistent }


    POPULATE_TEMPLATE( ch_params_consistent.TEMPLATE, ch_note_template )
    ch_versions = ch_versions.mix( POPULATE_TEMPLATE.out.versions.first() )

    if ( params.write_to_portal ) { 
        ch_api_url = Channel.of(params.genome_notes_api)
        WRITE_TO_GENOME_NOTES_DB( ch_params_consistent.DB, ch_api_url )
        ch_versions = ch_versions.mix( WRITE_TO_GENOME_NOTES_DB.out.versions.first() )
    }


    emit:
    template    = POPULATE_TEMPLATE.out.genome_note // channel: [ docx ]
    versions    = ch_versions.ifEmpty(null) // channel: [versions.yml]
    
}