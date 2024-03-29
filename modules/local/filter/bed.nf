process FILTER_BED {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::coreutils=8.25"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/coreutils:8.25--1' :
        'biocontainers/coreutils:8.25--1' }"

    input:
    tuple val(meta), path(bed)

    output:
    tuple val(meta), path("*.pairs"), emit: pairs
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    filter_bed.sh $bed ${prefix}_filtered.pairs

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash -version 2>&1 | grep -i bash | sed 's/GNU bash, version //; s/ .*//')
    END_VERSIONS
    """
}
