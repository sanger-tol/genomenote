// Obtain the basic feature statistics for example: Number og genes, CDS, exons, mRNA from the annotation file (gff3)

process BasicFeatureStats {
    
    // Specificying the output directory for annotation statistics files created
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
    path "versions.yml"                , emit: versions

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

   cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        agat : \$(agat --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
