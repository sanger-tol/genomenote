
process RUN_WGET {

    tag "${meta.source}|${meta.type}"
    label 'process_single'

    conda "bioconda::gnu-wget=1.18"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gnu-wget:1.18--h7132678_6' :
        'quay.io/biocontainers/gnu-wget:1.18--h7132678_6' }"

    input:
    tuple val(meta), val(url)


    output:
    tuple val(meta), path("${meta.id}_${meta.source}_${meta.type}*.${meta.ext}") , emit:  file_path
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def  no_certificate = (meta.source == 'GOAT') ? '--no-check-certificate' : ''
    def is_biosample = (meta.biosample_type == "WGS" || meta.biosample_type == "HIC" || meta.biosample_type == "RNA") ? "_${meta.biosample_type}" : ""
    def output = "${meta.id}_${meta.source}_${meta.type}${is_biosample}.${meta.ext}".strip('_')
    """
        wget ${no_certificate} -c -O ${output} '${url}'

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            wget: \$(wget --version | head -n 1 | cut -d' ' -f3)
        END_VERSIONS
    """
}
