process ADDMERQURY {
    tag "$meta.id"
    label 'process_single'

    conda (params.enable_conda ? "python=3.9.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1':
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    tuple val(meta), path(qv), path(completeness), path(summary)

    output:
    tuple val(meta), path("*.csv"), emit: csv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in sanger-tol/genomenote/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    def outname = summary.baseName + "_" + prefix.split('_')[0..-2].join('_')
    """
    add_merqury.py \\
        ${prefix} \\
        $qv \\
        $completeness \\
        ${outname}.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        add_merqury.py: \$(add_merqury.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
