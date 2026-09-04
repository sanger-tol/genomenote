//
// Create genome statistics table for genome notes
//

include { NCBIDATASETS_SUMMARYGENOME as SUMMARYGENOME   } from '../../../modules/local/ncbidatasets/summarygenome'
include { NCBIDATASETS_SUMMARYGENOME as SUMMARYSEQUENCE } from '../../../modules/local/ncbidatasets/summarygenome'
include { NCBI_GET_ODB                                  } from '../../../modules/local/ncbidatasets/get_odb'
include { BUSCO_BUSCO as BUSCO                          } from '../../../modules/nf-core/busco/busco/main'
include { RESTRUCTUREBUSCODIR                           } from '../../../modules/sanger-tol/restructurebuscodir'
include { FASTK_FASTK                                   } from '../../../modules/nf-core/fastk/fastk/main'
include { CREATETABLE                                   } from '../../../modules/local/createtable'
include { FASTK_HISTEX                                  } from '../../../modules/nf-core/fastk/histex/main'
include { GENESCOPEFK                                   } from '../../../modules/nf-core/genescopefk/main'
include { GFASTATS                                      } from '../../../modules/nf-core/gfastats/main'
include { MERQURYFK_MERQURYFK                           } from '../../../modules/nf-core/merquryfk/merquryfk/main'
include { BGZIPTABIX                                    } from '../../../modules/sanger-tol/bgziptabix/main'
include { UNTAR as UNTAR_KMER_DB                        } from '../../../modules/nf-core/untar/main'

workflow GENOME_STATISTICS {
    take:
    genome // channel: [ meta, fasta ]
    busco_taxid_lineage_mapping // channel: /path/to/busco_taxid_lineage_mapping
    busco_db // channel: /path/to/buscoDB
    pacbio // channel: [ meta, kmer_db or reads ]
    flagstat // channel: [ meta, flagstat ]
    haplotype // channel, value: list of [ meta, fasta ]

    main:
    ch_versions = channel.empty()


    //
    // MODULE: Genome summary statistics
    //
    SUMMARYGENOME(genome)
    ch_versions = ch_versions.mix(SUMMARYGENOME.out.versions.first())


    //
    // MODULE: Get genomic assembly statistics using GFASTATS
    //
    GFASTATS(
        genome,
        "",
        "",
        "",
        [[], []],
        [[], []],
        [[], []],
        [[], []],
    )
    ch_versions = ch_versions.mix(GFASTATS.out.versions)


    //
    // MODULE: Sequence summary statistics
    //
    SUMMARYSEQUENCE(genome)
    ch_versions = ch_versions.mix(SUMMARYSEQUENCE.out.versions.first())


    if (params.busco_lineage) {
        ch_lineage = channel.of(params.busco_lineage)
    }
    else {
        //
        // MODULE: GET RAW ODB LINEAGE VALUE
        //
        NCBI_GET_ODB(SUMMARYGENOME.out.summary, busco_taxid_lineage_mapping)
        ch_versions = ch_versions.mix(NCBI_GET_ODB.out.versions.first())


        //
        // LOGIC: FORMAT NCBI GET ODB OUTPUT INTO A CHANNEL OF val(lepidoptera_odb10) READY FOR BUSCO INPUT.
        //
        ch_lineage = NCBI_GET_ODB.out.csv
            .map { _meta, csv -> csv }
            .splitCsv()
            .map { row -> row[1] }
    }


    //
    // MODULE: RUN BUSCO
    //
    BUSCO(
        genome,
        "genome",
        ch_lineage,
        busco_db.ifEmpty([]),
        [],
        false,
    )
    ch_versions = ch_versions.mix(BUSCO.out.versions.first())
    busco_out_to_restructure = BUSCO.out.batch_summary
        .combine(ch_lineage)
        .join(BUSCO.out.short_summaries_txt, remainder: true)
        .join(BUSCO.out.short_summaries_json, remainder: true)
        .join(BUSCO.out.full_table, remainder: true)
        .join(BUSCO.out.missing_busco_list, remainder: true)
        .join(BUSCO.out.seq_dir)
        .map { meta, batch_summary, lineage, short_summaries_txt, short_summaries_json, full_table, missing_busco_list, busco_dir ->
            [meta, lineage, batch_summary, short_summaries_txt ?: [], short_summaries_json ?: [], full_table ?: [], missing_busco_list ?: [], busco_dir]
        }

    //
    // MODULE: Tidy up the BUSCO output directories before publication
    //
    RESTRUCTUREBUSCODIR(
        busco_out_to_restructure
    )

    //
    // LOGIC: Prepare channels for FastK, collect files in directory create list for FASTK
    //
    ch_pacbio = pacbio.branch { _meta, file ->
        dir: file.isDirectory()
        tar: file.name ==~ /.*\.tar(\.gz)?$/
        file: true
    }

    ch_fastk = ch_pacbio.file
        .map { meta, reads -> [meta.specimen, [meta, reads]] }
        .groupTuple()
        .map { _specimen, meta_reads ->
            if (meta_reads.size() == 1) {
                // Single file - no merge needed
                return [meta_reads[0][0], meta_reads[0][1]]
            } else {
                // Multiple files - merge them
                def meta_read = meta_reads[0][0]
                def runs = meta_reads.collect { meta, _read -> meta.run }
                def meta_merged = meta_read + [
                    'sample': "${meta_read.specimen}/${params.merge_output}",
                    'id': "${meta_read.specimen}.${params.merge_output}",
                    'run': 'merge',
                    'merge_source': runs.sort().join("\n"),
                ]
                def reads = meta_reads
                    .sort { a, b -> a[0].id <=> b[0].id }
                    .collect { _meta, read -> read }
                return [meta_merged, reads]
            }
        }

    //
    // MODULE: RUN FASTK KMER COUNTING TO GENERATE HISTOGRAM DATA
    //
    FASTK_FASTK(ch_fastk)


    //
    // MODULE: HISTEX generates a histogram in -h given intervals
    //
    FASTK_HISTEX(FASTK_FASTK.out.hist)


    //
    // MODULE: GENESCOPEFK PLOT THE KMER HISTOGRAM and
    //          outputs a correct estimate of genome size and % repetitiveness
    //
    GENESCOPEFK(FASTK_HISTEX.out.hist)


    //
    // LOGIC: Define channel for MERQURKFK
    //
    ch_combo = FASTK_FASTK.out.hist.join(FASTK_FASTK.out.ktab)

    UNTAR_KMER_DB(ch_pacbio.tar)
    ch_kmer_dir = ch_pacbio.dir.mix(UNTAR_KMER_DB.out.untar)

    ch_grab = ch_kmer_dir.map { meta, dir ->
        [
            meta,
            dir.listFiles().findAll { file -> file.toString().endsWith(".hist") }.collect(),
            dir.listFiles().findAll { file -> file.toString().contains(".ktab") }.collect(),
        ]
    }

    ch_merq = ch_combo
        .mix(ch_grab)
        .combine(genome)
        .combine(haplotype.map { l -> [l] })
        .map { meta, hist, ktab, meta2, fasta, hap_fasta ->
            [meta + [genome_size: meta2.genome_size, max_length: meta2.max_length], hist, ktab, fasta, hap_fasta]
        }


    // MerquryFK
    MERQURYFK_MERQURYFK(
        ch_merq,
        [[], []],
        [[], []],
    )

    // Compress the BED file
    ch_bed_with_seq_length = MERQURYFK_MERQURYFK.out.bed
        .map { meta, bed -> [meta, (bed instanceof List ? bed : [bed])] }
        .flatMap { meta, beds -> beds.collect { bed -> [meta, bed, meta.max_length] } }
    BGZIPTABIX(ch_bed_with_seq_length, [false, 0, false])

    //
    // LOGIC: PREPARE FOR THE FOR Combined table
    //
    ch_summary = SUMMARYGENOME.out.summary.join(SUMMARYSEQUENCE.out.summary)

    ch_busco = BUSCO.out.short_summaries_json.ifEmpty([[], []])

    ch_merqury = MERQURYFK_MERQURYFK.out.qv
        .join(MERQURYFK_MERQURYFK.out.stats)
        .toList()
        .map { lmqc ->
            [
                lmqc.collect { meta, _qv, _comp -> meta },
                lmqc.collect { _meta, qv, _comp -> qv },
                lmqc.collect { _meta, _qv, comp -> comp },
            ]
        }

    ch_flagstat = flagstat
        .toList()
        .map { lmf ->
            [
                lmf.collect { meta, _file -> meta },
                lmf.collect { _meta, file -> file },
            ]
        }


    //
    // MODULE: CREATETABLE ( ch_summary, ch_busco, ch_merqury, ch_flagstat )
    //
    CREATETABLE(
        ch_summary,
        ch_busco,
        ch_merqury,
        ch_flagstat,
    )
    ch_versions = ch_versions.mix(CREATETABLE.out.versions.first())


    //
    // LOGIC: BUSCO results for MULTIQC
    //
    multiqc = BUSCO.out.short_summaries_txt.ifEmpty([[], []])

    emit:
    summary_seq       = SUMMARYSEQUENCE.out.summary // channel: [ meta, summary ]
    summary           = CREATETABLE.out.csv // channel: [ csv ]
    multiqc // channel: [ meta, summary ]
    ch_busco_lineage  = ch_lineage // channel: [ lineage_name ]
    ch_gfastats       = GFASTATS.out.assembly_summary // channel: [ meta, assembly_summary ]
    ch_kmer_cov       = GENESCOPEFK.out.kmer_cov // channel: [ meta, kmer_coverage ]
    ch_linear_plot    = GENESCOPEFK.out.linear_plot // channel: [ meta, linear_plot ]
    ch_log_plot       = GENESCOPEFK.out.log_plot // channel: [ meta, log_plot ]
    ch_model          = GENESCOPEFK.out.model // channel: [ meta, model ]
    ch_summary        = GENESCOPEFK.out.summary // channel: [ meta, summary ]
    ch_trans_lin_plot = GENESCOPEFK.out.transformed_linear_plot // channel: [ meta, transformed_linear_plot ]
    ch_trans_log_plot = GENESCOPEFK.out.transformed_log_plot // channel: [ meta, transformed_log_plot ]
    busco_full_table  = BUSCO.out.full_table // channel: [ meta, busco_dir ]
    ch_complete_stats = MERQURYFK_MERQURYFK.out.stats // channel: [ meta, completeness_stats ]
    ch_bed            = BGZIPTABIX.out.gz_index // channel: [ meta, bed, gzi ]
    ch_qv             = MERQURYFK_MERQURYFK.out.qv // channel: [ meta, qv ]
    ch_assembly_qv    = MERQURYFK_MERQURYFK.out.assembly_qv // channel: [ meta, assembly_qv ]
    versions          = ch_versions // channel: [ versions.yml ]
}
