#!/usr/bin/env nextflow

//
// Fetch genome metadata for genome notes
//

include { RUN_WGET                  }       from '../../modules/local/run_wget'
include { PARSE_METADATA            }       from '../../modules/local/parse_metadata'
include { COMBINE_METADATA          }       from '../../modules/local/combine_metadata'
include { FETCHGBIFMETADATA         }       from '../../modules/local/fetch_gbif_metadata'

workflow GENOME_METADATA {
    take:
    ch_file_list        // channel: /path/to/genome_metadata_file_template

    main:
    ch_versions = Channel.empty()

    // Process the metadata file to extract URLs and identify GBIF URLs
    ch_file_list
    | splitCsv(header: ['source', 'type', 'url', 'ext'], skip: 1)
    | flatMap { row ->
        // Check if the URL is related to GBIF
        def isGbifUrl = row.url.startsWith("https://api.gbif.org")

        def genus = null
        def species = null

        // If it’s a GBIF URL, extract genus and species from the URL (or you can adjust this to extract from other fields)
        if (isGbifUrl) {
            def queryParams = row.url.split("\\?")[1]
            genus = queryParams.split("&").find { it.startsWith("genus") }?.split("=")[1]
            species = queryParams.split("&").find { it.startsWith("species") }?.split("=")[1]
        }

        // Pass GBIF-related rows to the FETCHGBIFMETADATA process
        if (genus && species) {
            return [genus, species]
        }

        // Return other metadata entries as usual
        def metadata = [
            id: params.assembly,
            taxon_id: params.taxon_id,
            source: row.source,
            type: row.type,
            url: row.url,
            ext: row.ext
        ]
        
        return [metadata]
    }
    | set { metadata_list }

    // Fetch GBIF metadata for GBIF-related entries
    metadata_list
    | filter { it.size() == 2 }  // Only pass entries with genus and species to FETCHGBIFMETADATA
    | FETCHGBIFMETADATA

    ch_versions = ch_versions.mix( FETCHGBIFMETADATA.out.versions.first() )

    // Continue with normal metadata parsing and combination process
    RUN_WGET ( metadata_list.filter { it.size() == 1 } )
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

    COMBINE_METADATA(ch_parsed_files, FETCHGBIFMETADATA.out.file_path)
    ch_versions = ch_versions.mix( COMBINE_METADATA.out.versions.first() )

    emit:
    consistent    = COMBINE_METADATA.out.consistent // channel: [ csv ]
    inconsistent  = COMBINE_METADATA.out.inconsistent // channel: [ csv ]
    versions      = ch_versions.ifEmpty(null) // channel: [versions.yml]
}
