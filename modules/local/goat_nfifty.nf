process GOAT_NFIFTY {
    tag "${meta.id}"
    label 'process_single'

    conda (params.enable_conda ? "conda-forge::curl=7.80.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/curl:7.80.0' :
        'docker://curlimages/curl:7.80.0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.json"), emit: json
    path "versions.yml",             emit: versions

    script:
    def asm = task.ext.asm ?: "${meta.id}"
    """
    curl -X 'GET' \
        'https://goat.genomehubs.org/api/v2/search?query=${asm}&result=assembly&includeEstimates=false&fields=contig_n50%2Cscaffold_n50' \
        -H 'accept: application/json' \
        > ${asm}.n50.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        curl: \$(curl --version | grep curl | cut -f 2 -d ' ')
    END_VERSIONS
    """
}
