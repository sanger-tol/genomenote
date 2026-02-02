process POPULATE_TEMPLATE {
    tag "${meta.id}"
    label 'process_single'


    conda "conda-forge::docxtpl=0.11.5"
    container "quay.io/sanger-tol/python_docx_template:0.11.5-c1"

    input:
    tuple val(meta), path(param_data)
    path(note_template)

    output:
    tuple val(meta), path("*.{docx,xml}"), emit: genome_note
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: meta.id
    def file_type = note_template.extension

    """
    populate_genome_note_template.py \\
        $param_data \\
        $note_template \\
        ${file_type} \\
        ${prefix}.${file_type}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        populate_genome_note_template.py: \$(populate_genome_note_template.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
