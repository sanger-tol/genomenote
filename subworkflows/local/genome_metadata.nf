#!/usr/bin/env nextflow

//
// Fetch genome metadata for genome notes
//

include { RUN_WGET                  }       from '../../modules/local/run_wget'
include { PARSE_METADATA            }       from '../../modules/local/parse_metadata'
include { COMBINE_METADATA          }       from '../../modules/local/combine_metadata'

workflow GENOME_METADATA {
    take:
    ch_file_list        // channel: /path/to/genome_metadata_file_template


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

    emit:
    consistent  = COMBINE_METADATA.out.consistent // channel: [ csv ]
    versions    = ch_versions.ifEmpty(null) // channel: [versions.yml]
    
}
