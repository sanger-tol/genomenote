include { BEDTOOLS_BAMTOBED       } from '../../modules/nf-core/bedtools/bamtobed/main'
include { GNU_SORT as BED_SORT    } from '../../modules/nf-core/gnu/sort/main'
include { GNU_SORT as FILTER_SORT } from '../../modules/nf-core/gnu/sort/main'
include { FILTER_BED              } from '../../modules/local/filter/bed'
include { COOLER_CLOAD            } from '../../modules/nf-core/cooler/cload/main'
include { COOLER_ZOOMIFY          } from '../../modules/nf-core/cooler/zoomify/main'
include { COOLER_DUMP             } from '../../modules/nf-core/cooler/dump/main'
include { UPLOAD_HIGLASS_DATA     } from '../../modules/local/upload_higlass_data'
include { GENERATE_HIGLASS_LINK   } from '../../modules/local/generate_higlass_link'

workflow HIGLASS_GENERATION {
    take:
    bam_tuple
    chrom_list
    cool_bin
    cool_order

    main:
    ch_versions = Channel.empty()
    ch_higlass_link = Channel.empty()

    // BAM to Bed
    BEDTOOLS_BAMTOBED ( bam_tuple )
    ch_versions = ch_versions.mix ( BEDTOOLS_BAMTOBED.out.versions.first() )


    // Sort the bed file by read name
    BED_SORT ( BEDTOOLS_BAMTOBED.out.bed )
    ch_versions = ch_versions.mix ( BED_SORT.out.versions.first() )


    // Filter the bed file
    // Pair the consecutive rows
    FILTER_BED ( BED_SORT.out.sorted )
    ch_versions = ch_versions.mix ( FILTER_BED.out.versions.first() )


    // Sort the filtered bed by chromosome name
    FILTER_SORT ( FILTER_BED.out.pairs )
    ch_versions = ch_versions.mix ( FILTER_SORT.out.versions.first() )


    // Create the `.cool` file
    FILTER_SORT.out.sorted
    | combine ( cool_bin )
    | map { meta, bed, bin -> [ meta, bed, [], bin ] }
    | set { ch_cooler }

    chrom_list
    | map { meta, list -> list }
    | first
    | set { ch_chromsizes }

    COOLER_CLOAD ( ch_cooler, ch_chromsizes )
    ch_versions = ch_versions.mix ( COOLER_CLOAD.out.versions.first() )


    // Create the `.mcool` file
    COOLER_CLOAD.out.cool
    | map { meta, cool, bin -> [ meta, cool ] }
    | set { ch_zoomify }

    COOLER_ZOOMIFY ( ch_zoomify )
    ch_versions = ch_versions.mix ( COOLER_ZOOMIFY.out.versions.first() )


    // Create the `.genome` file
    COOLER_CLOAD.out.cool
    | map { meta, cool, bin -> [ meta, cool, [] ] }
    | set { ch_dump }

    COOLER_DUMP ( ch_dump )
    ch_versions = ch_versions.mix ( COOLER_DUMP.out.versions.first() )


    // Optionally add the files to a HiGlass webserver

    if ( params.upload_higlass_data ) {
        UPLOAD_HIGLASS_DATA (COOLER_ZOOMIFY.out.mcool, COOLER_DUMP.out.bedpe, params.higlass_data_project_dir, params.higlass_upload_directory )
        ch_versions = ch_versions.mix ( UPLOAD_HIGLASS_DATA.out.versions.first() )

        GENERATE_HIGLASS_LINK (UPLOAD_HIGLASS_DATA.out.file_name, UPLOAD_HIGLASS_DATA.out.map_uuid, UPLOAD_HIGLASS_DATA.out.grid_uuid, params.higlass_url, UPLOAD_HIGLASS_DATA.out.genome_file)
        ch_versions = ch_versions.mix ( GENERATE_HIGLASS_LINK.out.versions.first() )
        ch_higlass_link = ch_higlass_link.mix ( GENERATE_HIGLASS_LINK.out.higlass_link.first() )
    }


    emit:
    cool     = COOLER_CLOAD.out.cool                    // tuple val(meta), val(cool_bin), path("*.cool")
    mcool    = COOLER_ZOOMIFY.out.mcool                 // tuple val(meta), path("*.mcool")
    grid     = COOLER_DUMP.out.bedpe                    // tuple val(meta), path("*.bedpe")
    link     = ch_higlass_link                          // channel: [ *_higlass_link.csv]
    versions = ch_versions                              // channel: [ versions.yml ]
}
