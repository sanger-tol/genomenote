process GOAT_ODB {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::requests=2.26.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/requests:2.26.0':
        'biocontainers/requests:2.26.0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.busco_odb.csv"), emit: csv
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    get_odb.py ${prefix} ${prefix}.busco_odb.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        get_odb.py: \$(get_odb.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
