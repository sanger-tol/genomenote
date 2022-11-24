process SUMMARYTABLE {
    tag "$meta.id"
    label 'process_single'

    conda (params.enable_conda ? "python=3.9.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1':
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    tuple val(meta), path(genome_summary), path(sequence_summary), path(busco)

    output:
    tuple val(meta), path("*.csv"), emit: csv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in sanger-tol/genomenote/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    summary_table.py \\
        $genome_summary \\
        $sequence_summary \\
        $busco \\
        ${prefix}.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        summary_table.py: \$(summary_table.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
