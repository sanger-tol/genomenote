
process PARSE_NCBI_ASSEMBLY {
    tag "${meta.ext}|${meta.type}"
    label 'process_single'

    conda "conda-forge::requests=2.26.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/requests:2.26.0' :
        'quay.io/biocontainers/requests:2.26.0' }"

    input:
    tuple val(meta), path(json)

    output:
    tuple val(meta), path("parsed.csv") , emit:  file_path
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in nf-core/genomenote/bin/
    """
    parse_json_ncbi_assembly.py \\
        $json \\
        parsed.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        parse_json_ncbi_assembly.py: \$(parse_json_ncbi_assembly.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
