//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'


workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv


    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_data_channel(it) }
        .set { data }


    emit:
    data                                      // channel: [ val(meta), data ]
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
