process ANCESTRAL_PLOT {
    label 'process_low'
    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "quay.io/sanger-tol/busco_painter:1.0.0-c2"

    input:
    tuple val(meta), path(comp_location)
    tuple val(meta), path(genome_index)

    output:
    path("*_buscopainter.png")  , emit: png_plot
    path("*_buscopainter.pdf")  , emit: pdf_plot
    path("versions.yml")        , emit: versions

    script:
    def args    = task.ext.args     ?: ''
    def prefix  = task.ext.prefix   ?: "${meta.id}"

    """
    plot_buscopainter.R \\
        -f ${comp_location} \\
        -p ${prefix} \\
        -i ${genome_index} \\
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
