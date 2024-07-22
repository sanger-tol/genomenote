// Include modules

include { decompress_gff3_file } from '../../modules/nf-core/gunzip/decompress.nf'
include { CountFeatures} from '../../modules/nf-core/gt/stat/feature_stats.nf'
include { ExtractExons} from '../../modules/nf-core/gt/stat/feature_stats.nf'
include { IntronLength} from '../../modules/nf-core/gt/stat/feature_stats.nf'
include { CalculateIntronStats} from '../../modules/nf-core/gt/stat/feature_stats.nf'
include { TabulateResults } from '../../modules/nf-core/gt/stat/feature_stats.nf'


workflow {
    // Create a channel from the input file
    gff_ch = Channel.fromPath(params.annotation_set)

    if (params.annotation_set.endsWith(".gff3.gz")) {
    // If it is gzipped, use the decompress_gff3_file process
    gff_ch = decompress_gff3_file(gff_ch)
    }

    // Proceed with the CountFeatures process
    count_features = CountFeatures(gff_ch)
    extract_exons = ExtractExons(gff_ch)
    intron_length = IntronLength(extract_exons)
    intron_stats = CalculateIntronStats(intron_length)
    // TabulateResults process
    TabulateResults(count_features, intron_stats)

}
