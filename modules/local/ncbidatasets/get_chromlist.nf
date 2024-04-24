process GET_CHROMLIST {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::jq=1.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/jq:1.6' :
        'biocontainers/jq:1.6' }"

    input:
    tuple val(meta), path(json)
    path ord

    output:
    tuple val(meta), path("*_chrom.list"), emit: list
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    get_chr_list.sh $json ${prefix}_chrom.list $ord

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(bash -version 2>&1 | grep -i bash | sed 's/GNU bash, version //; s/ .*//')
    END_VERSIONS
    """
}
