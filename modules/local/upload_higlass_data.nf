process UPLOAD_HIGLASS_DATA {
    tag "$meta.id"
    label 'process_single'

    container "bitnami/kubectl:1.27"

    input:
    tuple val(meta), path(mcool)
    tuple val(meta2), path(genome)
    val(species)
    val(assembly)
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

    def project_name = "${higlass_data_project_dir}/${species.replaceAll('\\s','_')}/${assembly}"
    def file_name = "${assembly}_${meta.id}"
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

    # Load them in Kubernetes

    echo "Delete .mcool file from server if already exists"
    tilesets=\$(kubectl exec \$pod_name -- python /home/higlass/projects/higlass-server/manage.py list_tilesets | (grep '${file_name}_map' || [ "\$?" == "1" ] ) | awk '{print substr(\$NF, 1, length(\$NF)-1)}')

    for f in \$tilesets; do
        echo "Deleting \$f"
        kubectl exec \$pod_name --  python /home/higlass/projects/higlass-server/manage.py delete_tileset --uuid \$f
    done

    echo "Loading .mcool file"
    kubectl exec \$pod_name --  python /home/higlass/projects/higlass-server/manage.py ingest_tileset --filename /higlass-temp/${project_name}/${file_name}.mcool --filetype cooler --datatype matrix --project-name ${project_name} --name ${file_name}_map --uid ${uid}_map

    map_uuid=\$(kubectl exec \$pod_name -- python /home/higlass/projects/higlass-server/manage.py list_tilesets | (grep '${file_name}_map' || [ "\$?" == "1" ] ) | awk '{print substr(\$NF, 1, length(\$NF)-1)}')
    echo "uuid of .mcool file is: \$map_uuid"

    echo "Delete .genome file from server if already exists"
    tilesets=\$(kubectl exec \$pod_name -- python /home/higlass/projects/higlass-server/manage.py list_tilesets | (grep '${file_name}_grid' || [ "\$?" == "1" ] ) | awk '{print substr(\$NF, 1, length(\$NF)-1)}')

    for f in \$tilesets; do
        echo "Deleting \$f"
        kubectl exec \$pod_name --  python /home/higlass/projects/higlass-server/manage.py delete_tileset --uuid \$f
    done

    echo "Loading .genome file"
    kubectl exec \$pod_name --  python /home/higlass/projects/higlass-server/manage.py ingest_tileset --filename /higlass-temp/${project_name}/${file_name}.genome --filetype chromsizes-tsv --datatype chromsizes --coordSystem ${assembly}_assembly --project-name ${project_name} --name ${file_name}_grid --uid ${uid}_grid

    grid_uuid=\$(kubectl exec \$pod_name -- python /home/higlass/projects/higlass-server/manage.py list_tilesets | (grep '${file_name}_grid' || [ "\$?" == "1" ] ) | awk '{print substr(\$NF, 1, length(\$NF)-1)}')
    echo "uuid of .genome file is: \$grid_uuid"

    file_name=${file_name}

    echo "done"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kubectl: \$(kubectl version --output=json | jq -r ".clientVersion.gitVersion")
    END_VERSIONS
    """
}
