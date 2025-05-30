process BLOBTK_PLOT {
    // A somewhat nuclear option
    // Linked to issue https://github.com/sanger-tol/genomenote/issues/184
    // Depending on the blob dataset in use, the grid option may not
    // work at all. This is down to the version of blobtoolkit used to
    // generate the blob.
    // Adding a check would overly complicate the module so for now
    // we can ignore errors, with the *assumption* it would only kill
    // runs in which the blobdir doesn't have the right data
    errorStrategy = 'ignore'

    tag "$blobtk_args.name"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container   = "docker.io/genomehubs/blobtk:0.6.5"

    input:
    tuple val(meta), path(fasta)
    path(dir_location)   // Genuine path location must be a path.
    val(online_location) // HTTPS location needs to remain a value
    each blobtk_args

    output:
    tuple val(meta), path("*.png"), emit: png
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args         = task.ext.args ?: ''
    def prefix       = task.ext.prefix ?: "${meta.id}_${blobtk_args.name}"
    def VERSION      = "0.6.5"
    def resource     = online_location ?: dir_location

    """
    blobtk plot \\
        -d $resource \\
        $blobtk_args.args \\
        $args \\
        -o ${prefix}.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blobtk: $VERSION
    END_VERSIONS
    """

    stub:
    def prefix       = task.ext.prefix ?: "${genome_accession}"
    def VERSION      = "0.6.5"
    """
    touch ${prefix}.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blobtk: $VERSION
    END_VERSIONS
    """
}
