process ANCESTRAL_PLOT {
    label 'process_low'
    tag "$meta.id"

    // Docker image available at the project github repository
    container "ghcr.io/sanger-tol/busco_painter:1.0.1"

    input:
    tuple val(meta), path(comp_location)
    tuple val(meta2), path(fai)

    output:
    tuple val(meta), path("*_buscopainter.png") , emit: png_plot
    tuple val(meta), path("*_buscopainter.pdf") , emit: pdf_plot
    path("versions.yml")                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "ANCESTRAL_PLOT module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args    = task.ext.args     ?: ''
    def prefix  = task.ext.prefix   ?: "${meta.id}"

    """
    plot_buscopainter.R \\
        -f ${comp_location} \\
        -p ${prefix} \\
        -i ${fai} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version | grep -oP "\\d+\\.\\d+\\.\\d+")
        plot_buscopainter.R: \$(plot_buscopainter.R -v)
    END_VERSIONS
    """

    stub:
    def args    = task.ext.args     ?: ''
    def prefix  = task.ext.prefix   ?: "${meta.id}"
    """
    touch ${comp_location}_buscopainter.png
    touch ${comp_location}_buscopainter.pdf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version | grep -oP "\\d+\\.\\d+\\.\\d+")
        plot_buscopainter.R: \$(plot_buscopainter.R -v)
    END_VERSIONS
    """
}
