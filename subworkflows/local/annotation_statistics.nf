// include modules from nf-core 

include { AGAT_SQSTATBASIC } from '../../modules/nf-core/agat/sqstatbasic/main.nf'
include { AGAT_SPSTATISTICS } from '../../modules/nf-core/agat/spstatistics/main.nf'
include { GUNZIP } from '../../modules/nf-core/gunzip/main.nf'


workflow {

    // Create a channel from the input file
    gff_ch = Channel.fromPath(params.annotation_set)

    // Map the GFF channel to create a tuple with metadata and the file
    gff_tuple_ch = gff_ch
        .map { file -> [ [ 'id': file.baseName ], file ] }

    // Handle gzipped files
    if (params.annotation_set.endsWith('.gz')) {
        ch_unzipped = GUNZIP(gff_tuple_ch).gunzip
    } else {
        ch_unzipped = gff_tuple_ch
    }

    // Obtain the basic summary statistics from the GFF3 file
    AGAT_SQSTATBASIC(ch_unzipped)
   
    // Obtain other feature stats e.g intron count & length etc
    AGAT_SPSTATISTICS(ch_unzipped)
    

}
