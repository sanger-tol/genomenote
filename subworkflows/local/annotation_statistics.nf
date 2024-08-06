// include modules from nf-core 

include { AGAT_SQSTATBASIC } from '../../modules/nf-core/agat/sqstatbasic/main.nf'
include { AGAT_SPSTATISTICS } from '../../modules/nf-core/agat/spstatistics/main.nf'
include { GUNZIP } from '../../modules/nf-core/gunzip/main.nf'


workflow ANNOTATION_STATS {

    take:  gff3

    main:
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
   
        // Other feature stats e.g intron count & length etc
        AGAT_SPSTATISTICS(ch_unzipped)

    emit:
        AGAT_SQSTATBASIC.out
        AGAT_SPSTATISTICS.out
    

}
