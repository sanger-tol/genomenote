process COMBINE_METADATA {
    tag "test"
    label 'process_single'

    conda "conda-forge::python=3.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
        val(test)
    

    output: 


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = []
    for (item in  test){
        def meta = item[0]
        def file = item[1]
        def arg = "--${meta.source}_${meta.type}_file".toLowerCase()
        args.add(arg)
        args.add(file)
    }

    """
        echo ${args.join(" ")}

        combine_parsed_data.py \\
        ${args.join(" ")} \\
        --out combined.csv

    """  

}