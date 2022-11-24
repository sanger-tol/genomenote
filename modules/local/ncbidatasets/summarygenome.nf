process NCBIDATASETS_SUMMARYGENOME {
    tag "$meta.id"
    label 'process_single'

    conda (params.enable_conda ? "conda-forge::ncbi-datasets-cli=14.2.2" : null)
    container "biocontainers/ncbi-datasets-cli:14.2.2_cv1"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.json"), emit: summary
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    datasets \\
        summary \\
        genome \\
        accession \\
        ${prefix} \\
        ${args} \\
        > ${prefix}.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ncbi-datasets-cli: \$(datasets --version | sed 's/^.*datasets version: //' )
    END_VERSIONS
    """
}
