process NCBIDATASETS_SUMMARYGENOME {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::ncbi-datasets-cli=15.12.0"
    container "docker.io/biocontainers/ncbi-datasets-cli:15.12.0_cv23.1.0-4"

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
        ${meta.id} \\
        ${args} \\
        > ${prefix}.json

    validate_datasets_json.py ${prefix}.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ncbi-datasets-cli: \$(datasets --version | sed 's/^.*datasets version: //')
    END_VERSIONS
    """
}
