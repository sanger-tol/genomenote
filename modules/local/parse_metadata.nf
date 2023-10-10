
process PARSE_METADATA {
    tag "${meta.ext}|${meta.source}|${meta.type}"
    label 'process_single'

    conda "conda-forge::python=3.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    tuple val(meta), path(json)

    output:
    tuple val(meta), path("${meta.source.toLowerCase()}_${meta.type.toLowerCase()}.csv") , emit:  file_path
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when


    script: // This script is bundled with the pipeline, in nf-core/genomenote/bin/
    def script_name = "parse_${meta.ext.toLowerCase()}_${meta.source.toLowerCase()}_${meta.type.toLowerCase()}.py"
    def output_file = "${meta.source.toLowerCase()}_${meta.type.toLowerCase()}.csv"
    """
    $script_name \\
        $json \\
        $output_file

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        $script_name: \$($script_name --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
