// include modules from nf-core 

include { AGAT_SPSTATISTICS } from '../modules/nf-core/agat/spstatistics/main'
include { AGAT_SPSTATISTICS } from '../modules/nf-core/agat/spstatistics/main'
include { GUNZIP            } from '../modules/nf-core/gunzip/main'


workflow ANNOTATION_STATS {

    take:
    gff            //  channel: /path/to/annotation file

    main:
    ch_versions = Channel.empty()


    // Map the GFF channel to create a tuple with metadata and the file
    gff
    | map { file -> [ [ 'id': file.baseName ], file ] }	
    | set {ch_gff_tupple} 

    // Compress the gff files if needed
    if (params.annotation_set.endsWith('.gz')) {
        ch_unzipped = GUNZIP(ch_gff_tupple).gunzip
    } else {
        ch_unzipped = ch_gff_tupple
    }


    // Basic Annotation summary statistics
    AGAT_SQSTATBASIC(ch_unzipped)
    ch_versions = ch_versions.mix ( AGAT_SQSTATBASIC.out.versions.first() )


    // Other feature stats e.g intron count & length etc
    AGAT_SPSTATISTICS(ch_unzipped)
    ch_versions = ch_versions.mix ( AGAT_SPSTATISTICS.out.versions.first() )


    emit:
    versions = ch_versions                       // channel: [ versions.yml ]
        
}
