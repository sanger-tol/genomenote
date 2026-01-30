/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK           } from '../subworkflows/local/input_check/main'
include { GENOME_METADATA       } from '../subworkflows/local/genome_metadata/main'
include { CONTACT_MAPS          } from '../subworkflows/local/contact_maps/main'
include { GENOME_STATISTICS     } from '../subworkflows/local/genome_statistics/main'
include { COMBINE_NOTE_DATA     } from '../subworkflows/local/combine_note_data/main'
include { ANNOTATION_STATISTICS } from '../subworkflows/local/annotation_statistics/main'
include { ANNOTATION_ANCESTRAL  } from '../subworkflows/local/annotation_ancestral/main'
include { GET_BLOBTK_PLOTS      } from '../subworkflows/local/get_blobtk_plots/main'


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
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'

include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_genomenote_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GENOMENOTE {

    take:
    samplesheet     // channel: samplesheet read in from --input
    metadata        // channel: list of accession numbers to retrieve metadata for
    lineage_db      // channel: path to the Busco lineage, if provided
    ancestral_table // channel: path to the ancestral painting table, if provided
    cool_order      // channel: path to the ordered list of chromosomes, if provided
    btk_local_path  // channel: path of a local blobDir, if provided
    btk_online_path // channel: path of a remote blobDir, if provided

    main:

    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    INPUT_CHECK ( samplesheet, metadata).data
    | branch { meta, file ->
        hic : meta.datatype == 'hic'
            return [ meta, file, [] ]
        pacbio : meta.datatype == 'pacbio' || meta.datatype == '10x'
            return [ meta, file ]
        haplotype : meta.datatype == 'haplotype'
            return [ meta, file ]
    }
    | set { ch_inputs }
    ch_versions  = ch_versions.mix ( INPUT_CHECK.out.versions )

    // Currently we only expect to see ONE haplotype so make this a constraint
    ch_inputs.haplotype
        // Remove meta otherwise collect() will include it as if it were an haplotype
        .map { meta, haplotype -> haplotype }
        .collect()
        .map { haplotype_tuples ->
            if (haplotype_tuples.size() > 1) {
                error "Multiple haplotype files detected (${haplotype_tuples}) and is not yet supported. Please only provide one haplotype file"
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
    ch_unzipped  = GUNZIP_HAPLOTYPE.out.gunzip
    ch_versions  = ch_versions.mix ( GUNZIP_HAPLOTYPE.out.versions )

    //
    // NOTE: Mix the unzipped haplotype with the original zipped haplotypes - this exists as a prelude to multi-haplotype support
    //
    ch_haplotype = ch_unzipped.mix(ch_haplotype.unzipped)

    //
    // MODULE: Uncompress fasta file if needed and set meta based on input params
    //

    INPUT_CHECK.out.param
    | map { meta -> [meta, params.fasta] }
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
        flagstat = file( reads.resolveSibling( reads.baseName + ".flagstat" ), checkIfExists: true)
        [ meta, flagstat ]
    }
    | set { ch_flagstat }

    GENOME_STATISTICS (
        ch_fasta,
        params.lineage_tax_ids,
        lineage_db,
        ch_inputs.pacbio,
        ch_flagstat,
        ch_haplotype
    )
    ch_versions  = ch_versions.mix ( GENOME_STATISTICS.out.versions )


    if (params.btk_location || params.btk_online_location) {
        //
        // SUBWORKFLOW: Grab blobtoolkit plots via API
        //
        GET_BLOBTK_PLOTS(
            ch_fasta,
            btk_local_path,
            btk_online_path,
        )
        ch_versions  = ch_versions.mix ( GET_BLOBTK_PLOTS.out.versions )
    }


    //
    // SUBWORKFLOW: Create contact map matrices from HiC alignment files
    //
    CONTACT_MAPS (
        ch_fasta,
        ch_inputs.hic,
        GENOME_STATISTICS.out.summary_seq,
        Channel.of(params.binsize),
        cool_order,
        params.select_contact_map
    )
    ch_versions  = ch_versions.mix ( CONTACT_MAPS.out.versions )


    //
    // SUBWORKFLOW : Obtain feature statistics from the annotation file : GFF
    //
    ch_annotation_stats = Channel.empty()
    if ( params.annotation_set ) {
        ANNOTATION_STATISTICS (
            Channel.fromPath(params.annotation_set),
            ch_fasta,
            GENOME_STATISTICS.out.ch_busco_lineage,
            lineage_db
        )
        ch_versions = ch_versions.mix ( ANNOTATION_STATISTICS.out.versions )
        ch_annotation_stats = ch_annotation_stats.mix (ANNOTATION_STATISTICS.out.summary)
    }

    if ( params.note_template ){

        //
        // SUBWORKFLOW: Read in template of data files to fetch, parse these files and output a list of genome metadata params
        //
        ch_file_list = Channel.fromPath("$projectDir/assets/genome_metadata_template.csv")
        INPUT_CHECK.out.param.combine( ch_file_list )
        | set { ch_metadata }

        GENOME_METADATA ( ch_metadata )
        ch_versions     = ch_versions.mix(GENOME_METADATA.out.versions)

        //
        // SUBWORKFLOW: Combine data from previous steps to create formatted genome note
        //
        COMBINE_NOTE_DATA (
            GENOME_METADATA.out.consistent,
            GENOME_METADATA.out.inconsistent,
            GENOME_STATISTICS.out.summary,
            ch_annotation_stats.ifEmpty([[],[]]),
            CONTACT_MAPS.out.link,
            params.note_template
        )
        ch_versions = ch_versions.mix ( COMBINE_NOTE_DATA.out.versions )
    }

    //
    // SUBWORKFLOW: Ancestral Element Analysis workflow - generates plots for user provided ancestral element mapping
    //              Only available for lepidoptera as of April 2025
    //              Once there are more options, this should be reviewed for a better system
    //

    if ( params.ancestral_table && params.ancestral_busco_lineage ) {
        ANNOTATION_ANCESTRAL (
            ch_fasta,
            ancestral_table,
            params.ancestral_busco_lineage,
            lineage_db
        )
        ch_versions = ch_versions.mix ( ANNOTATION_ANCESTRAL.out.versions )
    }

    //
    // Collate and save software versions
    //
    def topic_versions = Channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'genomenote_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        channel.fromPath(params.multiqc_config, checkIfExists: true) :
        channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )
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

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
