process GOAT_NFIFTY {
    tag "$asm_id"
    label 'process_single'

    conda (params.enable_conda ? "conda-forge::curl=7.83.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/curl:7.80.0' :
        'docker://curlimages/curl:7.84.0' }"

    input:
    val(asm_id)

    output:
    path "n50.json",      emit: json
    path "versions.yml", emit: versions

    script:
    """
    curl -X 'GET' 'https://goat.genomehubs.org/api/v2/search?query=${asm_id}&result=assembly&includeEstimates=false&summaryValues=count&taxonomy=ncbi&size=10&offset=0&fields=contig_n50%2Cscaffold_n50&names=&ranks=#${asm_id}' -H 'accept: application/json' > n50.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        curl: \$(curl --version | grep curl | cut -f 2 -d ' ')
    END_VERSIONS
    """
}
