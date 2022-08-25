process INPUT_TOL {
    label 'process_single'

    conda (params.enable_conda ? "conda-forge::gawk=5.1.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.1.0' :
        'quay.io/biocontainers/gawk:5.1.0' }"

    input:
    val tolid
    val project

    output:
    path "*.fasta",          emit: fasta
    path "samplesheet.csv",  emit: csv
    path "versions.yml",     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    tol_input.sh "$tolid" "$project" $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tol_input.sh: \$(tol_input.sh | tail -n 1 | cut -d' ' -f2)
    END_VERSIONS
    """
}
