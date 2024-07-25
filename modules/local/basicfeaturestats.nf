process BasicFeatureStats {
    

    publishDir "${params.outdir}/annotation_stats", mode: 'copy'
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/agat:1.4.0--pl5321hdfd78af_0' :
        'biocontainers/agat:1.4.0--pl5321hdfd78af_0' }"

    input:
    tuple val(meta), path(gff)

    output:
    tuple val(meta), path("*.txt"), emit: basic_feature_stats_txt

    when:
    task.ext.when == null || task.ext.when
     
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    agat_sq_stat_basic.pl \\
        -i $gff \\
        --output ${prefix}.basic_feature_stats.txt \\
        $args
    """
}
