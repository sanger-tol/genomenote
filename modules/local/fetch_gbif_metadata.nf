process FETCH_GBIF_METADATA {
    tag "$assembly"
    label 'process_single'

    conda "conda-forge::python=3.9.1"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/requests:2.26.0':
        'quay.io/biocontainers/requests:2.26.0'}"

    input:
    tuple val(assembly), val(species)


    output:
    path "*.csv", emit: file_path
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def script_name = "fetch_gbif_metadata.py"
    def output_file = "${assembly}_gbif_taxonomy.csv"

    """
    $script_name --species $species --output $output_file

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        requests: \$(python -c 'import requests; print(requests.__version__)')
    END_VERSIONS
    """
}
