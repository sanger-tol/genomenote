#!/usr/bin/env nextflow

//
// Fetch genome metadata for genome notes
//

include { RUN_WGET                  }       from '../../modules/local/run_wget'
include { PARSE_METADATA            }       from '../../modules/local/parse_metadata'
include { COMBINE_METADATA          }       from '../../modules/local/combine_metadata'
include { POPULATE_TEMPLATE         }       from '../../modules/local/populate_template'
include { WRITE_TO_GENOME_NOTES_DB  }       from '../../modules/local/write_to_database'

workflow GENOME_METADATA {
    take:
    ch_file_list        // channel: /path/to/genome_metadata_file_template
    ch_note_template   // channel: /path/to/genome_note_doc_template

    main:
    ch_versions = Channel.empty()
 
    // Define channel for RUN_WGET
    ch_file_list
    | splitCsv(header: ['source', 'type', 'url', 'ext'], skip: 1)
    | map { row -> 
        [   
            // meta
            [   id: params.assembly,
                taxon_id: params.taxon_id,
                source: row.source, 
                type: row.type, 
                ext: row.ext, 
            ],
            // url 
            row.url
                .replaceAll(/ASSEMBLY_ACCESSION/, params.assembly)
                .replaceAll(/TAXONOMY_ID/, params.taxon_id)
                .replaceAll(/BIOPROJECT_ACCESSION/, params.bioproject)
                .replaceAll(/BIOSAMPLE_ACCESSION/, params.biosample)
        ]
    }
    | set { file_list }

    // Fetch files
    RUN_WGET ( file_list )
    ch_versions = ch_versions.mix( RUN_WGET.out.versions.first() ) 

    PARSE_METADATA(RUN_WGET.out.file_path)
    ch_versions = ch_versions.mix( PARSE_METADATA.out.versions.first() )
    
    PARSE_METADATA.out.file_path 
    | map { it -> tuple( it[1] )}
    | collect  
    | map { it ->
        meta = [:]
        meta.id = params.assembly
        meta.taxon_id = params.taxon_id
        [ meta, it ]
    }
    | set { ch_parsed_files }

    COMBINE_METADATA(ch_parsed_files)
    ch_versions = ch_versions.mix( COMBINE_METADATA.out.versions.first() )


    COMBINE_METADATA.out.consistent
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
