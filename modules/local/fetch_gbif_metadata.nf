process FETCH_GBIF_METADATA {
    tag "${genus}"
    tag "${species}"

    conda "conda-forge::python=3.9.1 requests"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    val genus
    val species

    output:
    val "gbif_metadata.json", emit: file_path
    path "versions.yml", emit: versions

    script:
    def script_name = "fetch_gbif_metadata.py"
    """
    $script_name --genus $genus --species $species --output gbif_metadata.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
