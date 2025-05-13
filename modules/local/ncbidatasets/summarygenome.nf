process NCBIDATASETS_SUMMARYGENOME {
    tag "$meta.id"
    label 'process_single'
    secret 'NCBI_API_KEY'
    // Always expect that the NCBI API KEY is to be used here.
    // We can't do this in a def before the script block or it can
    // expand the variable and print it out!

    conda "conda-forge::ncbi-datasets-cli=16.22.1"
    container "docker.io/biocontainers/ncbi-datasets-cli:16.22.1_cv1"

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
        --api-key \$NCBI_API_KEY \\
        > ${prefix}.json

    validate_datasets_json.py ${prefix}.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ncbi-datasets-cli: \$(datasets --version | sed 's/^.*datasets version: //')
    END_VERSIONS
    """
}
