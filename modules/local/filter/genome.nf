process FILTER_GENOME {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::coreutils=8.25"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/coreutils:8.25--1' :
        'biocontainers/coreutils:8.25--1' }"

    input:
    tuple val(meta), path(fai)

    output:
    tuple val(meta), path("*.list"), emit: list
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cut -f1,2 $fai | sed 's/-/_/g' | sort -k2,2 -nr > ${prefix}_filtered.list

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash -version 2>&1 | grep -i bash | sed 's/GNU bash, version //; s/ .*//')
    END_VERSIONS
    """
}
