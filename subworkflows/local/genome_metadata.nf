#!/usr/bin/env nextflow

//
// Fetch genome metadata for genome notes
//

include { RUN_WGET                  }       from '../../modules/local/run_wget'
include { PARSE_METADATA            }       from '../../modules/local/parse_metadata'
include { COMBINE_METADATA          }       from '../../modules/local/combine_metadata'
include { FETCH_GBIF_METADATA       }       from '../../modules/local/fetch_gbif_metadata'


workflow GENOME_METADATA {
    take:
    ch_file_list        // channel: /path/to/genome_metadata_file_template


    main:
    ch_versions = Channel.empty()

    // Define channel for RUN_WGET
    ch_file_list
    | splitCsv(header: ['source', 'type', 'url', 'ext'], skip: 1)
    | flatMap { row ->
        // Create a list to hold the final entries
        def entries = []

        // Common metadata
        def metadata = [
            id: params.assembly,
            taxon_id: params.taxon_id,
            species: params.species, // Include species for GBIF fetch
            source: row.source,
            type: row.type,
            ext: row.ext
        ]

        // Define biosamples with their types
        def biosamples = [
            ["WGS", params.biosample_wgs],
            ["HIC", params.biosample_hic],
            ["RNA", params.biosample_rna]
        ]

        // Process each biosample
        biosamples.each { biosampleType, biosampleID ->
            if ( biosampleID != null ) {
                // Skip if biosampleID is null}
                def url = row.url
                    .replaceAll(/ASSEMBLY_ACCESSION/, params.assembly)
                    .replaceAll(/TAXONOMY_ID/, params.taxon_id)
                    .replaceAll(/BIOPROJECT_ACCESSION/, params.bioproject)
                    .replaceAll(/BIOSAMPLE_ACCESSION/, biosampleID)

                if (row.type == 'Biosample') {
                    // Add entry with biosample type in metadata for Biosample type
                    entries << [
                        metadata + [biosample_type: biosampleType],
                        url
                    ]
                } else {
                    // Add entry without biosample type in metadata for other types
                    entries << [
                        metadata + [biosample_type: ''],
                        url
                    ]
                }
            }
        }
        return entries
    }
    | unique()
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

    // Split params.species into genus and species
    def species_parts = params.species.split('-')
    def genus = species_parts[0]  
    def species = species_parts[1] 

    // Fetch GBIF metadata using the split genus and species
    FETCH_GBIF_METADATA(genus, species)
    ch_versions = ch_versions.mix(FETCH_GBIF_METADATA.out.versions.first() )


    COMBINE_METADATA(ch_parsed_files, FETCH_GBIF_METADATA.out.file_path )
    ch_versions = ch_versions.mix( COMBINE_METADATA.out.versions.first() )

    emit:
    consistent  = COMBINE_METADATA.out.consistent // channel: [ csv ]
    inconsistent  = COMBINE_METADATA.out.inconsistent // channel: [ csv ]
    versions    = ch_versions.ifEmpty(null) // channel: [versions.yml]
    
}