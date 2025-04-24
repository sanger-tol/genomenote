process ANCESTRAL_PLOT {
    label 'process_low'
    tag "$meta.id"

    // R MODULE CONTAINER

    input:
    tuple val(meta), path(comp_location)
    path(dup_location)
    path(summary)
    path(genome_index)

    output:
    path("ancestral_plot.png")  , emit: merian_plot
    path("versions.yml")        , emit: versions

    script:
    def args    = task.ext.args     ?: ''
    def prefix  = task.ext.prefix   ?: "${meta.id}"

    """

    """

    stub:
    def args    = task.ext.args     ?: ''
    def prefix  = task.ext.prefix   ?: "${meta.id}"
    """

    """

}
