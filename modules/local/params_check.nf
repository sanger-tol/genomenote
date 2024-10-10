process PARAMS_CHECK {
    tag "$assembly"
    label 'process_single'

    conda "conda-forge::python=3.10.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/requests:2.26.0':
        'quay.io/biocontainers/requests:2.26.0'}"

    input:
    tuple val(assembly), val(wgs_biosample), val(hic_biosample), val(rna_biosample)

    output:
    path '*.csv', emit: csv
    path "versions.yml", emit: versions

    script:
    """
    check_parameters.py \\
        --assembly $assembly \\
        --wgs_biosample $wgs_biosample \\
        --hic_biosample $hic_biosample \\
        --rna_biosample $rna_biosample \\
        --output ${assembly}_valid.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}

