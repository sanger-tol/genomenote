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

    // add some metadata params to the data channel meta with inline validation
    def seen_ids = [:]
    def genes_count = 0
    
    data = samplesheet
        .map { meta, datafile ->
            def sample = meta.id.toString()
            def sample_parts = sample.split("/", 2)
            def specimen = sample_parts[0]
            def run = sample_parts.length > 1 ? sample_parts[1] : ""
            def new_id = meta.id.replace("/",".")

            [meta.assembly, meta + [ "id": new_id, "sample": meta.id, "specimen": specimen, "run": run ], datafile]
        }
        .combine(ch_tmp_param, by: 0)
        .map { _assembly, meta, datafile, meta2 ->
            def new_meta = meta + [species: meta2.species, taxon_id: meta2.taxon_id]
            
            // INLINE VALIDATION - Check for duplicate sample IDs
            if (seen_ids.containsKey(new_meta.id)) {
                error("Sample cannot be duplicated (slash (`/`) and dot (`.`) treated as equivalent): ${new_meta.id}")
            }
            seen_ids[new_meta.id] = true

            // INLINE VALIDATION - Check genes count
            if (new_meta.datatype == "genes") {
                genes_count++
                if (genes_count > 1) {
                    error("Multiple genes rows detected. Please provide at most one genes row in the samplesheet.")
                }
            }

            [new_meta, datafile]
        }

    emit:
    data // channel: [ val(meta), data ]
    param // channel: [val(meta)]
    versions = PARAMS_CHECK.out.versions // channel: [ versions.yml ]
}