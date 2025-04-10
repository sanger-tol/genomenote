//
// Check input samplesheet and get read channels
//

include { PARAMS_CHECK      } from '../../modules/local/params_check'
include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'
include { HIFI_TRIMMER     } from '../../modules/nf-core/custom/hifi-trimmer/main'

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
        .map { create_data_channel(it, params.assembly) }
        .set { ch_data }

    // set temp key to allow combining channels
    param
        .map { meta ->
            [meta.id[0], meta]
        }
        .set { ch_tmp_param }

    // add some metadata params to the data channel meta
    ch_data
        .combine(ch_tmp_param, by: 0)
        .map { assembly, meta, sample, meta2 ->
            def new_meta = meta.clone()
            new_meta.species = meta2.species[0]
            new_meta.taxon_id = meta2.taxon_id[0]
            [new_meta, sample]
        }
        .set { data }

    // Apply hifi-trimmer to PacBio reads
    data
        .branch { meta, file ->
            pacbio: meta.datatype == 'pacbio'
                return [ meta, file ]
            default: true
                return [ meta, file ]
        }
        .set { ch_branched }

    HIFI_TRIMMER ( ch_branched.pacbio )
    ch_versions = SAMPLESHEET_CHECK.out.versions.mix(HIFI_TRIMMER.out.versions)

    // Combine trimmed and untrimmed reads
    ch_branched.default
        .mix(HIFI_TRIMMER.out.trimmed_reads)
        .set { ch_final_data }

    emit:
    data = ch_final_data                                   // channel: [ val(meta), data ]
    param                                  // channel: [val(meta)]  
    versions = ch_versions // channel: [ versions.yml ]
}


// Function to get list of [ meta, data ]
def create_data_channel(LinkedHashMap row, assembly) {
    // create meta map
    def meta = [:]
    meta.id         = row.sample
    meta.datatype   = row.datatype
    meta.assembly   = assembly

    // add path(s) of the data file(s) to the meta map
    return [ meta.assembly, meta, file(row.datafile) ]
}
