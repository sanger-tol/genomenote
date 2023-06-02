
process PARSE_GOAT_ASSEMBLY {
    tag "${meta.ext}|${meta.type}"
    label 'process_single'

    conda "conda-forge::python=3.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    tuple val(meta), path(json)

    output:
    tuple val(meta), path("parsed.csv") , emit:  file_path
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in nf-core/genomenote/bin/
    """
    parse_json_goat_assembly.py \\
        $json \\
        parsed.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parse_json_goat_assembly.py: \$(parse_json_goat_assembly.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
