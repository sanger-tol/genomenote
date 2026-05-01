//
// Check input samplesheet and get read channels
//

include { PARAMS_CHECK } from '../../../modules/local/params_check'


workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv
    cli_params // tuple, see below

    main:

    param = PARAMS_CHECK(cli_params).csv
        .splitCsv(header: true, sep: ',')
        .map { row ->
            def meta = [
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

    // set temp key to allow combining channels
    ch_tmp_param = param.map { meta ->
        [meta.id, meta]
    }

    // add some metadata params to the data channel meta
    data = samplesheet
        .map { meta, datafile -> 
            def new_id = meta.id.replaceAll("/", ".")
            [meta.assembly, meta + [ "id": new_id, "sample": meta.id ], datafile] 
        }
        .combine(ch_tmp_param, by: 0)
        .map { _assembly, meta, datafile, meta2 ->
            def new_meta = meta + [species: meta2.species, taxon_id: meta2.taxon_id]
            [new_meta, datafile]
        }
    
    // Check for duplicate sample IDs after transformation of slash in the input samplesheet
    data.map { meta, _ -> meta.id }
        .collect()
        .subscribe { list ->
            def duplicates = list.groupBy { it }.findAll { _, v -> v.size() > 1 }
            if (duplicates) error "Sample cannot be duplicated (slash (`/`) and dot (`.`) treated as equivalent): ${duplicates.keySet()}"
        }

    emit:
    data // channel: [ val(meta), data ]
    param // channel: [val(meta)]
    versions = PARAMS_CHECK.out.versions // channel: [ versions.yml ]
}
