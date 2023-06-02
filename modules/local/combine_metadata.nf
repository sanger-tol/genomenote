process COMBINE_METADATA {
    tag "${meta.ext}|${meta.type}"
    label 'process_single'

    conda "conda-forge::python=3.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
        tuple val(meta), path(xml)

    output: 


    when:
    task.ext.when == null || task.ext.when

    script: 
    """
    echo "$xml"
    """  

}