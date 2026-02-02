process NCBIDATASETS_SUMMARYGENOME {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::ncbi-datasets-cli=16.22.1"
    container "docker.io/biocontainers/ncbi-datasets-cli:16.22.1_cv1"

    errorStrategy { sleep(Math.pow(2, task.attempt) * 30 as long); return 'retry' }

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
