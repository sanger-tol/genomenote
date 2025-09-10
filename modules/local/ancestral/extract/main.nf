process ANCESTRAL_EXTRACT {
    tag "$meta.id"
    label 'process_low'

    // Docker image available at the project github repository
    container "ghcr.io/sanger-tol/busco_painter:1.0.1"

    input:
    tuple val(meta), path(fulltable)
    path(ancestraltable)

    output:
    tuple val(meta), path("*buscopainter_complete_location.tsv")  , emit: comp_location
    tuple val(meta), path("*buscopainter_duplicated_location.tsv"), emit: dup_location
    tuple val(meta), path("*summary.tsv")                         , emit: summary
    path "versions.yml"                                           , emit: versions

    script:
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "ANCESTRAL_EXTRACT module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args    = task.ext.args     ?: ''
    def prefix  = task.ext.prefix   ?: "${meta.id}"

    """
    buscopainter.py -r $ancestraltable -q $fulltable

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(echo \$(python3 --version 2>&1) | sed 's/^.*python //; s/Using.*\$//')
        buscopainter.py: \$(buscopainter.py -v)
    END_VERSIONS
    """

    stub:
    def prefix  = task.ext.prefix   ?: "${meta.id}"
    """
    touch ${prefix}_buscopainter_complete_location.tsv
    touch ${prefix}_buscopainter_duplicated_location.tsv
    touch ${prefix}_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(echo \$(python --version 2>&1) | sed 's/^.*python //; s/Using.*\$//')
        buscopainter.py: \$(buscopainter.py -v)
    END_VERSIONS
    """
}
