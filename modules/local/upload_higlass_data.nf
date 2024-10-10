process UPLOAD_HIGLASS_DATA {
    tag "$meta.id"
    label 'process_single'

    container "bitnami/kubectl:1.27"

    input:
    tuple val(meta), path(mcool)
    tuple val(meta2), path(genome)
    val(higlass_data_project_dir)
    path(upload_dir)

    output:
    env map_uuid, emit: map_uuid
    env grid_uuid, emit: grid_uuid
    env file_name, emit: file_name
    tuple val(meta2), path(genome), emit: genome_file
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "UPLOAD_HIGLASS_DATA modules do not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def assembly = "${meta.assembly}"
    def species = "${meta.species}"
    def project_name = "${higlass_data_project_dir}/${species.replaceAll('\\s','_')}/${assembly}"
    def file_name = "${assembly}_${meta.id}"
    // uid cannot contain a "."
    def uid = "${file_name.replaceAll('\\.','_')}"


    """
    # Configure kubectl access to the namespace
    export KUBECONFIG=$params.higlass_kubeconfig
    kubectl config get-contexts
    kubectl config set-context --current --namespace=$params.higlass_namespace

    # Find the name of the pod
    sel=\$(kubectl get deployments.apps $params.higlass_deployment_name --output=json | jq -j '.spec.selector.matchLabels | to_entries | .[] | "\\(.key)=\\(.value),"')
    sel2=\${sel%?}
    pod_name=\$(kubectl get pod --selector=\$sel2 --output=jsonpath={.items[0].metadata.name})
    echo "\$pod_name"

    # Copy the files to the upload area
    mkdir -p ${upload_dir}${project_name}
    cp -f $mcool ${upload_dir}${project_name}/${file_name}.mcool
    cp -f $genome ${upload_dir}${project_name}/${file_name}.genome


    # Loop over files to load them in Kubernetes

    files_to_upload=(".mcool" ".genome")

    for file_ext in \${files_to_upload[@]}; do
        echo "loading \$file_ext file"

        # Set file type and uuid to use for tileset. This uuid is needed for creating viewconfig.

        if [[ \$file_ext == ".mcool" ]]
        then
            file_type="map"
            map_uuid=${uid}_\${file_type}

        elif [[ \$file_ext == '.genome' ]]
        then
            file_type="grid"
            grid_uuid=${uid}_\${file_type}
        fi

        # Call the bash script to handle upload of file to higlass server

        upload_higlass_file.sh \$pod_name ${project_name} ${file_name} \$file_type \$file_ext ${uid} ${assembly}

        echo "\$file_ext loaded"
    done

    # Set file name to pass through to view config creation
    file_name=${file_name}

    echo "done"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kubectl: \$(kubectl version --output=json | jq -r ".clientVersion.gitVersion")
    END_VERSIONS
    """
}
