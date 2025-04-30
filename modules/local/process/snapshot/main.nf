process PROCESS_SNAPSHOT {
    tag "${meta.id}"
    label 'process_single'

    conda "conda-forge::python=3.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-9a9f31fdd4196df237c06c90e6e77fe27cdd5c1f%3A8148bc7b912a3499dffccc48ea2e197cdce37a33-0' :
        'quay.io/biocontainers/mulled-v2-9a9f31fdd4196df237c06c90e6e77fe27cdd5c1f:8148bc7b912a3499dffccc48ea2e197cdce37a33-0' }"

    input:
    tuple val(meta), path(png)          // channel: [ val(meta), path(file) ]
    tuple val(meta), path(chrom_list)   // channel: [ val(meta), path(file) ]
    val(exclusion_list)                 // ["SCAFFOLD_1", "SCAFFOLD_2"]

    output:
    tuple val (meta), path("${meta.id}_anotated.png"),  emit: png
    path "versions.yml",                                emit: versions

    script:
    def args        = task.ext.args     ?: ''
    def prefix      = task.ext.prefix   ?: meta.id
    def exclusion   = exclusion_list    ? "--exclusion_molecules ${exclusion_list}": ""
    """
    process_snapshot.py \\
        --input_png ${png} \\
        --chromosome_list ${chrom_list} \\
        --output_path ./${prefix}_anotated.png \\
        --font_path ${baseDir}/assets/Roboto-VariableFont_wdth,wght.ttf \\
        ${exclusion} \\
        ${args}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        process_snapshot.py: \$(process_snapshot.py --version)
    END_VERSIONS
    """

    stub:
    def prefix      = task.ext.prefix   ?: meta.id
    """
    touch ${prefix}_anotated.png

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        process_snapshot.py: \$(process_snapshot.py --version)
    END_VERSIONS
    """
}
