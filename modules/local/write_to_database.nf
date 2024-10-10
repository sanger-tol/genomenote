
process WRITE_TO_GENOME_NOTES_DB {
    secret 'TOL_API_KEY'

    tag = ""
    label 'process_single'

    conda "conda-forge::python=3.9.1"
    container "gitlab-registry.internal.sanger.ac.uk/tol-it/software/docker-images-test/tol_sdk:0.12.5-c1"
    input:
    tuple val(meta), path(param_data)
    val api_url

    output:
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in nf-core/genomenote/bin/
    """
    write_to_genome_notes_db.py \\
        $param_data             \\
        $api_url                \\
        \$TOL_API_KEY           \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        write_to_genome_notes_db.py: \$(write_to_genome_notes_db.py --version | cut -d' ' -f2)
    END_VERSIONS
    """
}
