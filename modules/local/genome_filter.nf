process GENOME_FILTER {
    tag "$index.simpleName"
    label 'process_nompi'

    conda (params.enable_conda ? "conda-forge::gawk=5.1.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'quay.io/biocontainers/gawk:5.1.0' }"

    input:
    path index

    output:
    path "*list",        emit: list
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${index.simpleName}"
    """
    genome_filter.sh $index ${prefix}.filtered.list

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        GNU Awk: \$(echo \$(awk --version 2>&1) | grep -i awk | sed 's/GNU Awk //; s/,.*//')
    END_VERSIONS
    """
}
