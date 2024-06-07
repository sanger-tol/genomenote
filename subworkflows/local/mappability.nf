//
// Create mappability tracks for genome notes
//
include { READNUMBERS    } from '../../modules/local/readnumbers'
include { WGSIM          } from '../../modules/nf-core/modules/nf-core/wgsim/main'
include { MINIMAP_ALIGN  } from '../../modules/nf-core/modules/nf-core/minimap/main'
include { SAMTOOLS_INDEX } from '../../modules/nf-core/modules/nf-core/samtools/index/main'
include { SAMTOOLS_VIEW  } from '../../modules/nf-core/modules/nf-core/samtools/view/main'


workflow MAPPABILITY {
    take:
    genome     // channel: [ meta, /path/to/fasta ]
    coverage   // channel: val(coverage); default: 30
    bed        // channel: /path/to/bed

    main:
    ch_versions = Channel.empty()

    // Calculate number of reads to generate by WGSIM
    READNUMBERS ( coverage )
    ch_versions = ch_versions.mix( READNUMBERS.out.versions.first() )

    // Simulate illumina reads from genome
    WGSIM ( genome, READNUMBERS.out.readnumbers )
    ch_versions = ch_versions.mix( WGSIM.out.versions.first() )

    // Align simulated reads back to genome
    MINIMAP_ALIGN ( WGSIM.out.fastq, genome.map { meta, file -> file }, true, [], [] )
    ch_versions = ch_versions.mix( MINIMAP_ALIGN.out.versions.first() )

    // Index BAM file
    SAMTOOLS_INDEX ( MINIMAP_ALIGN.out.bam )
    ch_versions = ch_versions.mix ( SAMTOOLS_INDEX.out.versions.first() )

    // Filter aligned sorted BAM file
    SAMTOOLS_VIEW ( SAMTOOLS_INDEX.out.bam )
    ch_versions = ch_versions.mix ( SAMTOOLS_INDEX.out.versions.first() )

    // Calculate coverage
    SAMTOOLS_DEPTH ( SAMTOOLS_INDEX.out.bam, bed )
    ch_versions = ch_versions.mix ( SAMTOOLS_DEPTH.out.versions.first() )

    // Calculate coverage and output in BED format
    //BEDTOOLS_COVERAGE (
}
