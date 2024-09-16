process FETCHGBIFMETADATA {

    conda "bioconda::gnu-wget=1.18"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gnu-wget:1.18--h7132678_6' :
        'quay.io/biocontainers/gnu-wget:1.18--h7132678_6' }"

    input:
    val genus
    val species

    output:
    path "species_details.json"
    path "versions.yml"

    script:
    """
        # Step 1: Query species match API
        wget -qO- "https://api.gbif.org/v1/species/match?verbose=true&genus=${genus}&species=${species}" > species_match.json

        # Extract usageKey from step 1 response
        usageKey=\$(jq '.usageKey' species_match.json)

        # Step 2: Query species lookup API using usageKey
        wget -qO- "https://api.gbif.org/v1/species/\${usageKey}" > species_details.json

        
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            wget: \$(wget --version | head -n 1 | cut -d' ' -f3)
        END_VERSIONS
    """
}

