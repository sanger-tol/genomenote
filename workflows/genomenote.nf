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
include { SAMTOOLS_VIEW               } from '../modules/local/samtools_view'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'

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
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Convert CRAM to BAM
    //
    ch_reads = INPUT_CHECK.out.aln.map { meta, reads -> [ meta, reads, [] ] }
    ch_fasta = INPUT_CHECK.out.genome.collect()
    SAMTOOLS_VIEW ( ch_reads, ch_fasta )
    ch_versions = ch_versions.mix(SAMTOOLS_VIEW.out.versions.first())

    //
    // SUBWORKFLOW: Create contact maps from BAM
    //
    ch_bin = Channel.of(params.binsize)
    CONTACT_MAPS (SAMTOOLS_VIEW.out.bam, SAMTOOLS_VIEW.out.fai, ch_bin)
    ch_versions = ch_versions.mix(CONTACT_MAPS.out.versions)

    //
    // SUBWORKFLOW: Create genome statistics table
    //
    CONTACT_MAPS.out.mcool.flatten().concat(ch_fasta.flatten()).toList()
        .map { meta, mcool, fasta ->
        new_meta = meta.clone()
        new_meta.id = fasta.baseName.replaceFirst(/.unmasked/, "").replaceFirst(/.subset/, "")
        [ [id: new_meta.id, outdir: new_meta.outdir], fasta ]
    }
    .set { ch_asm }
    ch_busco_db = Channel.of(params.lineage_db)
    ch_kmer = Channel.fromPath(params.kmer)

    GENOME_STATISTICS ( ch_asm, ch_busco_db, ch_kmer )
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
