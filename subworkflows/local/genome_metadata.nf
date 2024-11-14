#!/usr/bin/env nextflow

//
// Fetch genome metadata for genome notes
//

include { RUN_WGET                  }       from '../../modules/local/run_wget'
include { PARSE_METADATA            }       from '../../modules/local/parse_metadata'
include { COMBINE_METADATA          }       from '../../modules/local/combine_metadata'
include { FETCH_GBIF_METADATA       }       from '../../modules/local/fetch_gbif_metadata'
include { FETCH_ENSEMBL_METADATA    }       from '../../modules/local/fetch_ensembl_metadata'


workflow GENOME_METADATA {
    take:
    ch_file_list        // channel: [meta, /path/to/genome_metadata_file_template]
    
    main:
    ch_versions = Channel.empty()

    // Define channel for RUN_WGET
    ch_file_list
    | splitCsv(header: ['source', 'type', 'url', 'ext'], skip: 1)
    | flatMap { meta, row ->
        // Create a list to hold the final entries
        def entries = []

        def new_meta = meta + [source: row.source] + [type: row.type] + [ext: row.ext]
        

        // Define biosamples with their types
        def biosamples = [
            ["WGS", new_meta.biosample_wgs],
            ["HIC", new_meta.biosample_hic],
            ["RNA", new_meta.biosample_rna]
        ]

        // Process each biosample
        biosamples.each { biosampleType, biosampleID ->
            if ( biosampleID != null ) {
                // Skip if biosampleID is null}
                def url = row.url
                    .replaceAll(/ASSEMBLY_ACCESSION/, new_meta.id)
                    .replaceAll(/TAXONOMY_ID/, new_meta.taxon_id)
                    .replaceAll(/BIOPROJECT_ACCESSION/, new_meta.bioproject)
                    .replaceAll(/BIOSAMPLE_ACCESSION/, biosampleID)

                if (row.type == 'Biosample') {
                    // Add entry with biosample type in meta for Biosample type
                    entries << [
                        new_meta + [biosample_type: biosampleType],
                        url
                    ]
                } else {
                    // Add entry without biosample type in meta for other types
                    entries << [
                        new_meta + [biosample_type: ''],
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
    

    // Set channel for running GBIF
    ch_gbif_params = Channel.empty()

    ch_file_list
    | map { meta, it -> 
        def assembly = meta.id
        def species = meta.species
        [assembly, species]
    }
    | set { ch_gbif_params}
      
    // Fetch GBIF metdata using genus, species and id as input channels
    FETCH_GBIF_METADATA( ch_gbif_params )
    ch_versions = ch_versions.mix(FETCH_GBIF_METADATA.out.versions.first() )

    // Combining the two output channels into one  channel
    FETCH_GBIF_METADATA.out.file_path
    | map { it -> tuple( it )}
    | set { ch_gbif }

    // Query Ensembl Metadata API to see if this species has been annotated
    FETCH_ENSEMBL_METADATA ( ch_gbif_params )
    ch_versions = ch_versions.mix( FETCH_ENSEMBL_METADATA.out.versions.first() )    

    PARSE_METADATA.out.file_path
    | map { it -> tuple( it[1] )}
    | set { ch_parsed }

    ch_parsed.mix(ch_gbif, FETCH_ENSEMBL_METADATA.out.file_path)
    | collect  
    | map { it ->  
        [ it ]
    }
    | set { ch_parsed_files } 

    // Set meta required for file parsing
    ch_file_list
    | map { meta, it -> 
       [id: meta.id, taxon_id: meta.taxon_id]
    }
    | set {ch_meta}

    // combine meta and parsed files
    ch_meta_parsed = ch_meta.combine(ch_parsed_files)
 

    COMBINE_METADATA( ch_meta_parsed )
    ch_versions = ch_versions.mix( COMBINE_METADATA.out.versions.first() )

    emit:
    consistent  = COMBINE_METADATA.out.consistent // channel: [ csv ]
    inconsistent  = COMBINE_METADATA.out.inconsistent // channel: [ csv ]
    versions    = ch_versions.ifEmpty(null) // channel: [versions.yml]
    
}
