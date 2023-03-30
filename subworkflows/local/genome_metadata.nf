#!/usr/bin/env nextflow

//
// Fetch genome metadata for genome notes
//

include { RUN_WGET                  } from '../../modules/local/run_wget'

workflow GENOME_METADATA {
    take:
    assembly            // val: genbank assembly accession
    tax_id              // val: ncbi taxonomy id
    bioproject          // val: bioproject accession
    biosample           // val: biosample accession
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
                .replaceAll(/ASSEMBLY_ACCESSION/, assembly)
                .replaceAll(/TAXONOMY_ID/, tax_id)
                .replaceAll(/BIOPROJECT_ACCESSION/, bioproject)
                .replaceAll(/BIOSAMPLE_ACCESSION/, biosample)
        ] }
        .set{file_list}

    // Fetch files
    RUN_WGET ( file_list ) 

    ch_versions = ch_versions.mix(RUN_WGET.out.versions.first())

    ch_all_files = Channel.empty()
    .mix( RUN_WGET.out.file_path)

    emit:
    files       = ch_all_files // path: downloaded files
    versions    = ch_versions.ifEmpty(null) // channel: [versions.yml]
}

workflow {
    // path to metadata file template
    ch_file_list = Channel.fromPath('/lustre/scratch123/tol/teams/tolit/users/by3/pipelines/genomenote/assets/genome_metadata_template.csv')   

    result = GENOME_METADATA (
        'GCA_922984935.2',
        '9662',
        'PRJEB49353',
        'SAMEA7524400',
        ch_file_list
    )
    result.files.view ()
}