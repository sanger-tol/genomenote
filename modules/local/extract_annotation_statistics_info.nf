// EXtracting essential annotation statistics information from the output txt files
process EXTRACT_ANNOTATION_STATISTICS_INFO {
    
    label 'process_single'
    conda "conda-forge::python=3.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"
    input:
    tuple val(meta), path(basic_stats) 
    tuple val(meta), path(other_stats) 

    output:
    path("$meta.csv"), emit: csv
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when
    script:
    """
    echo "Basic stats file: $basic_stats"
    echo "Other stats file: $other_stats"

    bin/extract_annotation_statistics_info.py \\
        $basic_stats \\
        $other_stats \\
        assemblyID.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}

