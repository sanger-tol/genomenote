process COMBINE_STATISTICS_AND_METADATA {
    tag "${meta.id}"
    label 'process_single'

    conda "conda-forge::python=3.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    tuple val(meta), path(consistent_params)
    tuple val(meta2), path(inconsistent_params)
    tuple val(meta3), path(genome_statistics_params)
    tuple val(meta4), path(annotation_statistics_params)

    output:
    tuple val (meta), path("${meta.id}_genome_note_consistent.csv") , emit: consistent
    tuple val (meta), path("${meta.id}_genome_note_inconsistent.csv") , emit: inconsistent
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: meta.id
    def annotation = annotation_statistics_params ? "--in_annotation_statistics $annotation_statistics_params" : ''

    """
    echo 
    combine_statistics_data.py \\
    --in_consistent $consistent_params \\
    --in_inconsistent $inconsistent_params \\
    --in_genome_statistics $genome_statistics_params \\
    --out_consistent ${prefix}_genome_note_consistent.csv \\
    --out_inconsistent ${prefix}_genome_note_inconsistent.csv \\
    $annotation \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        combine_statistics_data.py: \$(combine_statistics_data.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
