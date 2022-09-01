process CREATE_TABLE {
    label 'process_single'

    conda (params.enable_conda ? "conda-forge::python=3.9.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    path json

    output:
    path "genome_statistics.csv",   emit: csv
    path "versions.yml", emit: versions

    script: // This script is bundled with the pipeline, in nf-core/genomenote/bin/
    """
    create_table.py $json genome_statistics.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        create_table.py: \$(create_table.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
