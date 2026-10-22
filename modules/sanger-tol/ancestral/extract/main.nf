process ANCESTRAL_EXTRACT {
    tag "$meta.id"
    label 'process_low'

    // Docker image available at the project github repository
    container "ghcr.io/sanger-tol/busco_painter:1.0.1"

    input:
    tuple val(meta), path(fulltable)
    tuple val(meta2), path(ancestraltable)

    output:
    tuple val(meta), path("*_complete_location.tsv")  , emit: comp_location
    tuple val(meta), path("*_duplicated_location.tsv"), emit: dup_location
    tuple val(meta), path("*_summary.tsv")            , emit: summary
    tuple val("${task.process}"), val('python'), eval('echo \$(python3 --version 2>&1) | sed "s/^.*python //; s/Using.*\$//"'), emit: versions_python, topic: versions
    tuple val("${task.process}"), val('buscopainter.py'), eval('buscopainter.py -v'), emit: versions_buscopainter, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "ANCESTRAL_EXTRACT module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args    = task.ext.args     ?: ''
    def prefix  = task.ext.prefix   ?: "${meta.id}"
    """
    buscopainter.py \\
        -r ${ancestraltable} \\
        -q ${fulltable} \\
        -p ${prefix} \\
        ${args}
    """

    stub:
    def prefix  = task.ext.prefix   ?: "${meta.id}"
    def args = task.ext.args     ?: ''
    """
    echo ${args}
    touch ${prefix}_complete_location.tsv
    touch ${prefix}_duplicated_location.tsv
    touch ${prefix}_summary.tsv
    """
}
