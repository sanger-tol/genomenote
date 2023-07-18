process COMBINE_METADATA {
    tag "combine_parsed"
    label 'process_single'

    conda "conda-forge::python=3.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    tuple val(meta), val(file_list)

    output:
    tuple val (meta), path("consistent.csv") , emit: consistent
    tuple val (meta), path("inconsistent.csv") , emit: inconsistent
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = []
    for (item in  file_list){
        def meta_file = item[0]
        def file = item[1]
        def arg = "--${meta_file.source}_${meta_file.type}_file".toLowerCase()
        args.add(arg)
        args.add(file)
    }

    """
    combine_parsed_data.py \\
    ${args.join(" ")} \\
    --out_consistent consistent.csv \\
    --out_inconsistent inconsistent.csv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        combine_parsed_data.py: \$(combine_parsed_data.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
