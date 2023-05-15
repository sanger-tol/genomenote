#!/usr/bin/env nextflow

//
// Fetch genome metadata for genome notes
//

include { RUN_WGET     }                from '../../modules/local/run_wget'
include { PARSE_ENA_ASSEMBLY   }   from '../../modules/local/parse_ena_assembly'

workflow GENOME_METADATA {
    take:
    ch_file_list        // channel: /path/to/genome_metadata_file_template

    main:
    ch_versions = Channel.empty()

    // Define channel for RUN_WGET
    ch_file_list
        .splitCsv(header: ['source', 'type', 'url', 'ext'], skip: 1)
        .map { row -> [
            // meta
            [ 
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
        ] }
        .set{file_list}

    // Fetch files
    RUN_WGET ( file_list ) 

    ch_versions = ch_versions.mix(RUN_WGET.out.versions.first())

    // Change this to branch code to manage passing of downloaded files to the appropriate parsing module    
    //ch_all_files = Channel.empty()
    //.mix( RUN_WGET.out.file_path)



    ch_input = RUN_WGET.out.file_path.branch { 
        ENA_ASSEMBLY: it[0].source == "ENA"  && it[0].type == "Assembly"
    }

    PARSE_ENA_ASSEMBLY ( ch_input.ENA_ASSEMBLY )
    ch_versions = ch_versions.mix(PARSE_ENA_ASSEMBLY.out.versions.first())


    emit:
    versions    = ch_versions.ifEmpty(null) // channel: [versions.yml]
}