process COMBINE_METADATA {
    tag "${meta.id}"
    label 'process_single'

    conda "conda-forge::python=3.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    tuple val(meta), path(file_list)

    output:
    tuple val (meta), path("${meta.id}_consistent.csv"), emit: consistent
    tuple val (meta), path("${meta.id}_inconsistent.csv"), emit: inconsistent
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = []
    def prefix = task.ext.prefix ?: meta.id
    for (item in  file_list){
        def file = item
        def file_ext = item.getExtension()
        def file_name = "--" + item.getName().minus("${prefix}_").minus(".${file_ext}").toLowerCase() + "_file"
        args.add(file_name)
        args.add(file)
    }

    """
    combine_parsed_data.py \\
    ${args.join(" ")} \\
    --out_consistent ${prefix}_consistent.csv \\
    --out_inconsistent ${prefix}_inconsistent.csv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        combine_parsed_data.py: \$(combine_parsed_data.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
