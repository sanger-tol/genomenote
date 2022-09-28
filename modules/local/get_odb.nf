process GET_ODB {
    tag "${meta.id}"
    label 'process_single'

    conda (params.enable_conda ? "conda-forge::requests=2.28.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/requests:2.26.0' :
        'quay.io/biocontainers/requests:2.26.0' }"
    
    input:
    tuple val(meta), path(fasta)

    output:
    path("*.busco_odb.csv"), emit: csv
    path "versions.yml",     emit: versions

    script: // This script is bundled with the pipeline, in sanger-tol/genomenote/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    get_odb.py ${prefix} ${prefix}.busco_odb.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        get_odb.py: \$(get_odb.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}