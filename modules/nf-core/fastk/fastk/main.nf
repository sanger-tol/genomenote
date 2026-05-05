process FASTK_FASTK {
    tag "$meta.id"
    label 'process_medium'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b5/b5b07773b60921f43e2839edab692377dcd725d4041adff5520838154e46f487/data' :
        'community.wave.seqera.io/library/fastk:1.2--580652dfcc8e7a12' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.hist")                      , emit: hist
    tuple val(meta), path("*.ktab*", hidden: true)       , emit: ktab, optional: true
    tuple val(meta), path("*.{prof,pidx}*", hidden: true), emit: prof, optional: true
    tuple val(meta), path("SOURCE.txt")                  , emit: source_txt, optional: true
    // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    tuple val("${task.process}"), val('fastk'), eval('echo 1.2'), emit: versions_fastk, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def source_files_args = meta.merge_source ? "&& cat > SOURCE.txt <<'SOURCE_TXT_EOF'\n${meta.merge_source}\nSOURCE_TXT_EOF" : ""
    """
    FastK \\
        $args \\
        -T$task.cpus \\
        -M${task.memory.toGiga()} \\
        -N${prefix} \\
        $reads \\
        ${source_files_args}

    find . -name '*.ktab*' -exec chmod a+r {} \\;
    """

    stub:
    def args       = task.ext.args ?: ''
    def prefix     = task.ext.prefix ?: "${meta.id}"
    def touch_ktab = args.contains('-t') ? "touch ${prefix}.ktab .${prefix}.ktab.1" : ''
    def touch_prof = args.contains('-p') ? "touch ${prefix}.prof .${prefix}.pidx.1" : ''
    def source_files_args = meta.merge_source ? "&& cat > SOURCE.txt <<'SOURCE_TXT_EOF'\n${meta.merge_source}\nSOURCE_TXT_EOF" : ""
    """
    touch ${prefix}.hist \\
    ${source_files_args}
    $touch_ktab
    $touch_prof

    echo \\
    "FastK \\
        $args \\
        -T$task.cpus \\
        -M${task.memory.toGiga()} \\
        -N${prefix}_fk \\
        $reads"
    """
}
