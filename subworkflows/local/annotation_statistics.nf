// include modules from nf-core 

include { AGAT_SQSTATBASIC } from '../../modules/nf-core/agat/sqstatbasic/main.nf'
include { AGAT_SPSTATISTICS } from '../../modules/nf-core/agat/spstatistics/main.nf'
include { GUNZIP } from '../../modules/nf-core/gunzip/main.nf'


workflow ANNOTATION_STATS {

    take:
    gff3            //  channel: /path/to/annotation file

    main:
    ch_versions = Channel.empty()


    // Map the GFF channel to create a tuple with metadata and the file
    gff3
    | map { file -> [ [ 'id': file.baseName ], file ] }	
    | set {ch_gff3_tupple} 

    // Compress the gff3 files if needed
    if (params.annotation_set.endsWith('.gz')) {
        ch_unzipped = GUNZIP(ch_gff3_tupple).gunzip
    } else {
        ch_unzipped = ch_gff3_tupple
    }


    // Basic Annotation summary statistics
    AGAT_SQSTATBASIC(ch_unzipped)
    ch_versions = ch_versions.mix ( AGAT_SQSTATBASIC.out.versions.first() )


    // Other feature stats e.g intron count & length etc
    AGAT_SPSTATISTICS(ch_unzipped)
    ch_versions = ch_versions.mix ( AGAT_SPSTATISTICS.out.versions.first() )


    emit:
    basic_features = AGAT_SQSTATBASIC.out        // channel: [ stats.txt]
    other_features = AGAT_SPSTATISTICS.out       // channel: [ stats.txt]
    versions = ch_versions                       // channel: [ versions.yml ]
        
}
