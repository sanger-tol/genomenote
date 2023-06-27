process POPULATE_TEMPLATE {
    label 'process_single'


    conda "conda-forge::docxtpl=0.11.5"
    container "frostasm/python-docx-template"

    input:
    path(param_data)
    path(note_template)

    output:
    path("note.docx"), emit: file_path_inconsistent
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    populate_genome_note_template.py \\
        $param_data \\
        $note_template \\
        note.docx

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        populate_genome_note_template.py: \$(populate_genome_note_template.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
