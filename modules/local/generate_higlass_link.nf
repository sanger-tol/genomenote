process GENERATE_HIGLASS_LINK {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::requests=2.26.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/requests:2.26.0':
        'biocontainers/requests:2.26.0' }"

    input:
    val(file_name)
    val(map_uuid)
    val(grid_uuid)
    val(server)
    tuple val(meta), path(genome)

    output:
    tuple val(meta), path("${meta.id}_higlass_link.csv"), emit: higlass_link
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in nf-core/genomenote/bin/
    def prefix = task.ext.prefix ?: meta.id
    """
    generate_higlass_link.py \\
        $file_name \\
        $map_uuid \\
        $grid_uuid \\
        $server \\
        $genome \\
        ${prefix}_higlass_link.csv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        generate_higlass_link.py: \$(generate_higlass_link.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
