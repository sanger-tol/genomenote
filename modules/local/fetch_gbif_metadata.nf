process FETCH_GBIF_METADATA{
    tag "${genus}"
    tag "${species}"
    tag "${meta.id}"
    label 'process_single'

    conda "conda-forge::python=3.9.1 "
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    val genus
    val species
    tuple val(meta), path(param_assembly id)

    output:
    path "*.csv", emit: file_path
    path "versions.yml", emit: versions
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def script_name = "fetch_gbif_metadata.py"
    def prefix = task.ext.prefix ?: meta.id
    def output_file = "${prefix}.csv"    

    """
    $script_name --genus $genus --species $species --output $output_file 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
