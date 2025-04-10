process HIFI_TRIMMER {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hifi-trimmer:1.0.0--hdfd78af_0' :
        'quay.io/biocontainers/hifi-trimmer:1.0.0--hdfd78af_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: trimmed_reads
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    hifi-trimmer \\
        -i $reads \\
        -o ${meta.id}.trimmed.fastq.gz \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hifi-trimmer: \$(hifi-trimmer --version 2>&1)
    END_VERSIONS
    """
} 