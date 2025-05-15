/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowGenomenote.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.lineage_db, params.fasta, params.lineage_tax_ids ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Mandatory parameters formatting and channeling
metadata_inputs = [ params.assembly ]

ch_input = Channel.fromPath(params.input)
ch_fasta = Channel.fromPath(params.fasta)
ch_bin   = Channel.of(params.binsize)
ch_kmer  = Channel.of(params.kmer_size)

if (params.lineage_tax_ids) { ch_lineage_tax_ids = Channel.fromPath(params.lineage_tax_ids) } else { exit 1, 'Mapping BUSCO lineage equivalent taxon_ids not specified' }

// Check optional parameters
if (params.lineage_db) { ch_lineage_db = Channel.fromPath(params.lineage_db) } else { ch_lineage_db = Channel.empty() }
if (params.note_template) { ch_note_template = Channel.fromPath(params.note_template) } else { ch_note_template = Channel.empty() }
if (params.cool_order) { ch_cool_order = Channel.fromPath(params.cool_order) } else { ch_cool_order = Channel.empty() }
if (params.annotation_set) { ch_gff = Channel.fromPath(params.annotation_set) } else { ch_gff = Channel.empty()}

if (params.biosample_wgs) metadata_inputs.add(params.biosample_wgs) else metadata_inputs.add(null)
if (params.biosample_hic) metadata_inputs.add(params.biosample_hic) else metadata_inputs.add(null)
if (params.biosample_rna) metadata_inputs.add(params.biosample_rna) else metadata_inputs.add(null)


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_metdata_input           = Channel.of( metadata_inputs )
ch_file_list               = Channel.fromPath("$projectDir/assets/genome_metadata_template.csv")
ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK           } from '../subworkflows/local/input_check'
include { GENOME_METADATA       } from '../subworkflows/local/genome_metadata'
include { CONTACT_MAPS          } from '../subworkflows/local/contact_maps'
include { GENOME_STATISTICS     } from '../subworkflows/local/genome_statistics'
include { COMBINE_NOTE_DATA     } from '../subworkflows/local/combine_note_data'
include { ANNOTATION_STATISTICS } from '../subworkflows/local/annotation_statistics'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { GUNZIP as GUNZIP_PRIMARY    } from '../modules/nf-core/gunzip/main'
include { GUNZIP as GUNZIP_HAPLOTYPE  } from '../modules/nf-core/gunzip/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow GENOMENOTE {

    ch_versions = Channel.empty()
    ch_annotation_stats = Channel.empty()
    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK ( ch_input, ch_metdata_input ).data
    | branch { meta, file ->
        hic : meta.datatype == 'hic'
            return [ meta, file, [] ]
        pacbio : meta.datatype == 'pacbio' || meta.datatype == '10x'
            return [ meta, file ]
        haplotype : meta.datatype == 'haplotype'
            return [ meta, file ]
    }
    | set { ch_inputs }
    ch_versions = ch_versions.mix ( INPUT_CHECK.out.versions )

    // Currently we only expect to see ONE haplotype so make this a constraint
    ch_inputs.haplotype
        .collect()
        .map { haplotype_tuples ->
            if (haplotype_tuples.size() > 2) {
                error "Multiple haplotype files detected and is not yet supported. Please only provide one haplotype file"
            }
        }


    //
    // MODULE: Unzip the input haplotype if zipped
    //
    ch_inputs.haplotype
    | branch { meta, fasta ->
        gzipped: fasta.name.endsWith('.gz')
        unzipped: true
    }
    | set { ch_haplotype }

    GUNZIP_HAPLOTYPE (
        ch_haplotype.gzipped
    )
    ch_unzipped = GUNZIP_HAPLOTYPE.out.gunzip
    ch_versions = ch_versions.mix ( GUNZIP_HAPLOTYPE.out.versions )

    //
    // NOTE: Mix the unzipped haplotype with the original zipped haplotypes - this exists as a prelude to multi-haplotype support
    //
    ch_haplotype = ch_unzipped.mix(ch_haplotype.unzipped)


    //
    // SUBWORKFLOW: Read in template of data files to fetch, parse these files and output a list of genome metadata params
    //
    INPUT_CHECK.out.param.combine( ch_file_list )
    | set { ch_metadata }


    GENOME_METADATA ( ch_metadata )
    ch_versions = ch_versions.mix(GENOME_METADATA.out.versions)

    //
    // MODULE: Uncompress fasta file if needed and set meta based on input params
    //

    INPUT_CHECK.out.param.combine( ch_fasta )
    | set { ch_genome }

    if ( params.fasta.endsWith('.gz') ) {
        ch_unzipped = GUNZIP_PRIMARY ( ch_genome ).gunzip
        ch_versions = ch_versions.mix ( GUNZIP_PRIMARY.out.versions.first() )
    } else {
        ch_unzipped = ch_genome
    }

    ch_unzipped
    | map { meta, fa -> [ meta + [id: fa.baseName, genome_size: fa.size()], fa] }
    | set { ch_fasta }


    //
    // SUBWORKFLOW: Create genome statistics table
    //
    ch_inputs.hic
    | map{ meta, reads, blank ->
        flagstat = file( reads.resolveSibling( reads.baseName + ".flagstat" ), checkIfExists: true )
        [ meta, flagstat ]
    }
    | set { ch_flagstat }

    GENOME_STATISTICS (
        ch_fasta,
        ch_lineage_tax_ids,
        ch_lineage_db,
        ch_inputs.pacbio,
        ch_flagstat,
        ch_haplotype
    )
    ch_versions = ch_versions.mix ( GENOME_STATISTICS.out.versions )


    //
    // SUBWORKFLOW: Create contact map matrices from HiC alignment files
    //
    CONTACT_MAPS (
        ch_fasta,
        ch_inputs.hic,
        GENOME_STATISTICS.out.summary_seq,
        ch_bin,
        ch_cool_order
    )
    ch_versions = ch_versions.mix ( CONTACT_MAPS.out.versions )


    //
    // SUBWORKFLOW : Obtain feature statistics from the annotation file : GFF
    //
    if ( params.annotation_set ) {
        ANNOTATION_STATISTICS (ch_gff, ch_fasta, GENOME_STATISTICS.out.ch_busco_lineage, ch_lineage_db)
        ch_versions = ch_versions.mix ( ANNOTATION_STATISTICS.out.versions )
        ch_annotation_stats = ch_annotation_stats.mix (ANNOTATION_STATISTICS.out.summary)
    }


    //
    // SUBWORKFLOW: Combine data from previous steps to create formatted genome note
    //
    COMBINE_NOTE_DATA (
        GENOME_METADATA.out.consistent,
        GENOME_METADATA.out.inconsistent,
        GENOME_STATISTICS.out.summary,
        ch_annotation_stats.ifEmpty([[],[]]),
        CONTACT_MAPS.out.link,
        ch_note_template
    )
    ch_versions = ch_versions.mix ( COMBINE_NOTE_DATA.out.versions )


    //
    // MODULE: Combine different versions.yml
    //
    CUSTOM_DUMPSOFTWAREVERSIONS ( ch_versions.unique().collectFile(name: 'collated_versions.yml') )


    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowGenomenote.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowGenomenote.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(ch_flagstat.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(GENOME_STATISTICS.out.multiqc.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )
    multiqc_report = MULTIQC.out.report.toList()

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
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
