//
// Take either ToL inputs to create samplesheet and get genome
// or use provided samplesheet and genome
// check them and create appropriate channels for downstream analysis
//

include { INPUT_TOL         } from '../../modules/local/input_tol'
include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    inputs     // either [ file(params.input), file(params.fasta) ] or [ params.input, params.project ]

    main:
    ch_versions = Channel.empty()

    // If ToL ID and project is used create samplesheet and copy genome
    ch_input = Channel.empty()
    inputs.multiMap { input, fasta ->
        csv  : input
        fasta: fasta
    }
    .set{ch_input}

    if (params.input && params.fasta) {
        genome      = ch_input.fasta
        samplesheet = ch_input.csv
        tol         = 0
    } else if (params.input && params.project) {
        INPUT_TOL (ch_input.csv, ch_input.fasta)
        genome      = INPUT_TOL.out.fasta
        samplesheet = INPUT_TOL.out.csv
        tol         = 1
        // ch_versions = ch_versions.mix(INPUT_TOL.out.versions)
    }
    
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_data_channels(it, tol) }
        .set { aln }
    // ch_versions = ch_versions.mix(SAMPLESHEET_CHECK.out.versions)

    emit:
    aln                                       // channel: [ val(meta), [ datafile ] ]
    genome                                    // channel: fasta
    // versions = ch_versions                 // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ datafile ] ]
def create_data_channels(LinkedHashMap row, tol) {
    def meta = [:]
    meta.id         = row.sample
    meta.datatype   = row.datatype
    meta.outdir     = (tol == 1) ? row.datafile.split('/')[0..10].join('/') : "${params.outdir}"

    def array = []
    array = [ meta, [ file(row.datafile) ] ]
    return array
}
