/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowGenomenote.initialise(params, log)

// Check mandatory parameters
if (params.input && params.fasta) { inputs = [ file(params.input, checkIfExists: true), file(params.fasta) ] }
else if (params.input && params.project) { inputs = [ params.input, params.project ] }
else { exit 1, 'Input not specified. Please include either a samplesheet or Tree of Life organism and project IDs' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK       } from '../subworkflows/local/input_check'
include { CONTACT_MAPS      } from '../subworkflows/local/contact_maps'
include { GENOME_STATISTICS } from '../subworkflows/local/genome_statistics'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow GENOMENOTE {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    Channel.of ( inputs ).set { ch_input }

    INPUT_CHECK ( ch_input )
    .aln
    .branch { meta, file ->
        hic : meta.datatype == "hic"
            return [ meta, file, [] ]
        kmer : meta.datatype != "hic"
            return [ meta, file ]
    }.set { ch_inputs }
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // SUBWORKFLOW: Create contact map matrices from CRAM alignment files
    //
    ch_fasta = INPUT_CHECK.out.genome.map { fasta -> [ [ id: fasta.baseName.replaceFirst(/.unmasked/, "").replaceFirst(/.subset/, "") ], fasta ] }
    ch_bin = Channel.of(params.binsize)

    CONTACT_MAPS (ch_fasta, ch_inputs.hic, ch_bin)
    ch_versions = ch_versions.mix(CONTACT_MAPS.out.versions)

    //
    // SUBWORKFLOW: Create genome statistics table
    //
    ch_asm = ch_inputs.hic.combine ( ch_fasta ).map { meta1, cram, blank, meta2, fasta -> [ [ id: meta2.id, outdir: meta1.outdir ], fasta ] }
    ch_buscoDB = Channel.of(params.lineage_db)
    ch_flagstat = ch_inputs.hic.map{ meta, cram, blank -> [ meta, file((cram.parent + "/" + cram.baseName + ".flagstat").join(""), checkIfExists: true) ] }
    
    GENOME_STATISTICS ( ch_asm, ch_buscoDB, ch_inputs.kmer, ch_flagstat )
    ch_versions = ch_versions.mix(GENOME_STATISTICS.out.versions)
    
    //
    // MODULE: Combine different versions.yml
    //
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
