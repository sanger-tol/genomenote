process MERQURYFK_MERQURYFK {
    tag "$meta.id"
    label 'process_medium'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    container 'quay.io/sanger-tol/fastk:1.0.1-c1'

    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit 1, "MERQURYFK_MERQURYFK module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    input:
    tuple val(meta), path(fastk_hist), path(fastk_ktab), path(assembly), path(haplotigs)

    output:
    tuple val(meta), path("${prefix}.completeness.stats") , emit: stats
    tuple val(meta), path("${prefix}.*_only.bed")         , emit: bed
    tuple val(meta), path("${prefix}.*.qv")               , emit: assembly_qv
    tuple val(meta), path("${prefix}.*.spectra-cn.fl.png"), emit: spectra_cn_fl_png,  optional: true
    tuple val(meta), path("${prefix}.*.spectra-cn.fl.pdf"), emit: spectra_cn_fl_pdf,  optional: true
    tuple val(meta), path("${prefix}.*.spectra-cn.ln.png"), emit: spectra_cn_ln_png,  optional: true
    tuple val(meta), path("${prefix}.*.spectra-cn.ln.pdf"), emit: spectra_cn_ln_pdf,  optional: true
    tuple val(meta), path("${prefix}.*.spectra-cn.st.png"), emit: spectra_cn_st_png,  optional: true
    tuple val(meta), path("${prefix}.*.spectra-cn.st.pdf"), emit: spectra_cn_st_pdf,  optional: true
    tuple val(meta), path("${prefix}.qv")                 , emit: qv
    tuple val(meta), path("${prefix}.spectra-asm.fl.png") , emit: spectra_asm_fl_png, optional: true
    tuple val(meta), path("${prefix}.spectra-asm.fl.pdf") , emit: spectra_asm_fl_pdf, optional: true
    tuple val(meta), path("${prefix}.spectra-asm.ln.png") , emit: spectra_asm_ln_png, optional: true
    tuple val(meta), path("${prefix}.spectra-asm.ln.pdf") , emit: spectra_asm_ln_pdf, optional: true
    tuple val(meta), path("${prefix}.spectra-asm.st.png") , emit: spectra_asm_st_png, optional: true
    tuple val(meta), path("${prefix}.spectra-asm.st.pdf") , emit: spectra_asm_st_pdf, optional: true
    path "versions.yml"                                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def FASTK_VERSION = '427104ea91c78c3b8b8b49f1a7d6bbeaa869ba1c' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    def MERQURY_VERSION = 'd00d98157618f4e8d1a9190026b19b471055b22e' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    MerquryFK \\
        $args \\
        -T$task.cpus \\
        ${fastk_ktab.find{ it.toString().endsWith(".ktab") }} \\
        $assembly \\
        $haplotigs \\
        $prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastk: $FASTK_VERSION
        merquryfk: $MERQURY_VERSION
        r: \$( R --version | sed '1!d; s/.*version //; s/ .*//' )
    END_VERSIONS
    """
}
