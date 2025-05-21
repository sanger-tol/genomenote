process BLOBTK_PLOT {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container   = "docker.io/genomehubs/blobtk:0.6.5"

    input:
    tuple val(meta), path(fasta)
    path(dir_location)

    output:
    tuple val(meta), path("*.png"), emit: png
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args         = task.ext.args ?: ''
    def prefix       = task.ext.prefix ?: "${meta.id}"
    def VERSION      = "0.6.5"

    """
    blobtk plot \\
        -d $dir_location \\
        $args \\
        -o ${prefix}.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blobtk: $VERSION
    END_VERSIONS
    """

    stub:
    """
    def prefix = task.ext.prefix ?: "${genome_accession}"
    touch ${prefix}.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blobtk: $VERSION
    END_VERSIONS
    """
}
