//
// Check input samplesheet and get read channels
//

include { PARAMS_CHECK      } from '../../modules/local/params_check'
include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'


workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv
    cli_params // tuple, see below


    main:

    PARAMS_CHECK ( cli_params )
        .csv
        .splitCsv (header:true, sep: ',')
    |   map { row ->
        meta = [
            id: row.assembly,
            species: row.species,
            taxon_id: row.taxon_id,
            bioproject: row.bioproject,
            biosample_wgs: row.wgs_biosample,
        ]
    
        if (row.hic_biosample != "null") {
            meta.biosample_hic = row.hic_biosample
        }
        
        if (row.rna_biosample != "null") {
            meta.biosample_rna = row.rna_biosample
        }

        [meta]
    } 
    | set { param }
    
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_data_channel(it) }
        .set { data }


    emit:
    data                                      // channel: [ val(meta), data ]
    param                                     // channel: [val(meta)]  
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}


// Function to get list of [ meta, data ]
def create_data_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.sample
    meta.datatype   = row.datatype

    // add path(s) of the data file(s) to the meta map
    return [ meta, file(row.datafile) ]
}
