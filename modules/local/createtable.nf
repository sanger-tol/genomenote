process CREATETABLE {
    tag "$meta.id"
    label 'process_single'

    conda (params.enable_conda ? "python=3.9.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1':
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    tuple val(meta), path(genome_summary), path(sequence_summary)
    path(busco)
    tuple val(meta2), path(qv), path(completeness)

    output:
    tuple val(meta), path("*.csv"), emit: csv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in sanger-tol/genomenote/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    def gen = genome_summary ? "--genome ${genome_summary}" : ""
    def seq = sequence_summary ? "--sequence ${sequence_summary}" : ""
    def bus = busco ? "--busco ${busco}" : ""
    def pac = qv ? "--pacbio ${meta2.id}" : ""
    def mqv = qv ? "--qv ${qv}" : ""
    def mco = completeness ? "--completeness ${completeness}" : ""
    """
    create_table.py \\
        $gen \\
        $seq \\
        $bus \\
        $pac \\
        $mqv \\
        $mco \\
        -o ${prefix}.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        create_table.py: \$(summary_table.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
