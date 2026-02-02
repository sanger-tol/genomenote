process RESTRUCTUREBUSCODIR {
    tag "${meta.id}_${lineage}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), val(lineage), path(batch_summary), path(short_summaries_txt), path(short_summaries_json), path(busco_dir)

    output:
    tuple val(meta), path("${lineage}"), emit: clean_busco_dir
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${lineage}

    cp --dereference ${batch_summary}        ${lineage}/short_summary.tsv
    [ -n "${short_summaries_txt}"  ] && cp --dereference ${short_summaries_txt}  ${lineage}/short_summary.txt
    [ -n "${short_summaries_json}" ] && cp --dereference ${short_summaries_json} ${lineage}/short_summary.json

    # Should we compress these ?
    [ -e ${busco_dir}/*/run_*/full_table.tsv         ] && cp ${busco_dir}/*/run_*/full_table.tsv         ${lineage}/
    [ -e ${busco_dir}/*/run_*/missing_busco_list.tsv ] && cp ${busco_dir}/*/run_*/missing_busco_list.tsv ${lineage}/

    # We run Busco in --tar mode, so these outputs are already compressed
    cp ${busco_dir}/*/run_*/busco_sequences/*.tar.gz  ${lineage}/
    cp ${busco_dir}/*/run_*/hmmer_output.tar.gz       ${lineage}/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tar: \$(tar --version| awk 'NR==1 {print \$3}' )
    END_VERSIONS
    """
}
