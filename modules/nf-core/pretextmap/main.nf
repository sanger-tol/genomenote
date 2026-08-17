
process PRETEXTMAP {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "quay.io/sanger-tol/pretext:0.0.9-yy5-c2"

    input:
    tuple val(meta), path(input)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fai)

    output:
    tuple val(meta), path("*.pretext")  , emit: pretext
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args     ?: '' // PretextMap args
    def args2       = task.ext.args2    ?: '' // Samtools view args
    def prefix      = task.ext.prefix   ?: "${meta.id}"
    def reference   = fasta             ? "--reference ${fasta}" : ""
    """
    if [[ $input == *.pairs.gz ]]; then
        zcat $input | PretextMap \\
            $args \\
            -o ${prefix}.pretext
    else
        samtools \\
            view \\
            $args2 \\
            $reference \\
            -h \\
            $input | \\
        PretextMap \\
            $args \\
            -o ${prefix}.pretext
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pretextmap: \$(PretextMap | sed '/Version/!d; s/.*Version //')
        samtools: \$(samtools --version | sed '1!d; s/samtools //')
    END_VERSIONS
    """

    stub:
    def prefix      = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.pretext

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pretextmap: \$(PretextMap | sed '/Version/!d; s/.*Version //')
        samtools: \$(samtools --version | sed '1!d; s/samtools //')
    END_VERSIONS
    """
}
