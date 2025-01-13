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
    ch_params_consistent // channel: /path/to/csv/file/consistent_parameters from GENOME_METADATA subworkflow
    ch_params_inconsistent // channel: /path/to/csv/file/consistent_parameters from GENOME_METADATA subworkflow
    ch_summary // channel: /path/to/csv/summary/file from GENOME_STATISTICS subworkflow 
    ch_annotation_summary // channel: /path/to/csv/summary/file from ANNOTATION_STATISTICS subworkflow
    ch_higlass // channel: /path/to/csv/higlass_link from CONTACT_MAPS subworkflow 
    ch_note_template   // channel: /path/to/genome_note_doc_template


    main:
    ch_versions = Channel.empty()

    ch_summary 
    | map {  meta, json ->
        [ meta + [
            ext:    "csv",
            source: "genome",
            type:   "summary",
        ], json ]
    }
    | set { ch_summary_meta }


    PARSE_METADATA(ch_summary_meta)
    ch_versions = ch_versions.mix( PARSE_METADATA.out.versions.first() )

    COMBINE_STATISTICS_AND_METADATA(ch_params_consistent, ch_params_inconsistent, PARSE_METADATA.out.file_path, ch_annotation_summary)
    ch_versions = ch_versions.mix( COMBINE_STATISTICS_AND_METADATA.out.versions.first() )

    ch_higlass
    | map { it -> [ [id: params.assembly] , it ] }

    
    // Add higlass url to the parsed dataset
    COMBINE_STATISTICS_AND_METADATA.out.consistent.concat(ch_higlass)
    .map { it ->
        it[1]
    }
    .collectFile(name: 'combined.csv', sort: false) { it ->
        it.text
    }
    .map { it -> [ [id: params.assembly] , it ] }
    .set { ch_parsed }

    POPULATE_TEMPLATE( ch_parsed, ch_note_template )
    ch_versions = ch_versions.mix( POPULATE_TEMPLATE.out.versions.first() )

    if ( params.write_to_portal ) { 
        ch_api_url = Channel.of(params.genome_notes_api)
        WRITE_TO_GENOME_NOTES_DB( COMBINE_STATISTICS_AND_METADATA.out.consistent, ch_api_url )
        ch_versions = ch_versions.mix( WRITE_TO_GENOME_NOTES_DB.out.versions.first() )
    }


    emit:
    template    = POPULATE_TEMPLATE.out.genome_note // channel: [ docx ]
    versions    = ch_versions.ifEmpty(null) // channel: [versions.yml]
    
}