// EXtracting essential annotation statistics information from the output txt files
process EXTRACT_ANNOTATION_STATISTICS_INFO {
    publishDir "${params.outdir}/annotation_stats", mode: 'copy'
    label 'process_single'
    conda "conda-forge::python=3.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"
    input:
    tuple val(sample_id),  path(basic_stats_txt)
    tuple val(sample_id),  path(other_stats_txt)
    output:
    tuple val(sample_id), path("*.csv"), emit: file_path
    path "versions.yml", emit: versions
    when:
    task.ext.when == null || task.ext.when
    script:
     // Define the prefix, using task.ext.prefix if provided, otherwise default to sample_id
    def prefix = task.ext.prefix ?: sample_id
    // Define the output file name using the prefix
    def output_file = "${prefix}.csv"
    """
    bin/extract_annotation_statistics_info.py \\
        $basic_stats \\
        $other_stats \\
        $output_file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}

