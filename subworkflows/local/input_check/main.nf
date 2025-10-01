//
// Check input samplesheet and get read channels
//

include { PARAMS_CHECK      } from '../../../modules/local/params_check'


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

        meta
    }
    | set { param }

    // set temp key to allow combining channels
    param
        .map { meta ->
            [meta.id, meta]
        }
        .set { ch_tmp_param }

    // add some metadata params to the data channel meta
    samplesheet
        .map { meta, datafile -> [meta.assembly, meta, datafile] }
        .combine(ch_tmp_param, by: 0)
        .map { assembly, meta, datafile, meta2 ->
            def new_meta = meta + [species: meta2.species, taxon_id: meta2.taxon_id]
            [new_meta, datafile]
        }
        .set { data }

    emit:
    data                                   // channel: [ val(meta), data ]
    param                                  // channel: [val(meta)]
    versions = PARAMS_CHECK.out.versions   // channel: [ versions.yml ]
}
