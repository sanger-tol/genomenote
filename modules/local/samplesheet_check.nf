process SAMPLESHEET_CHECK {
    tag "$samplesheet"
    label 'process_single'

    conda "conda-forge::python=3.10.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.10.2':
        'biocontainers/python:3.10.2' }"

    input:
    path samplesheet

    output:
    path '*.csv'       , emit: csv
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in sanger-tol/genomenote/bin/
    """
    check_samplesheet.py \\
        $samplesheet \\
        samplesheet.valid.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
