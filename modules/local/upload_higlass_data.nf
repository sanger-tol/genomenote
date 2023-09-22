process UPLOAD_HIGLASS_DATA {
    tag "$meta.id"
    label 'process_single'

    container "bitnami/kubectl:1.27"

    input:
    tuple val(meta), path(mcool)
    tuple val(meta2), path(genome)
    val(higlass_data_basedir)
    val(species)
    val(assembly)
    path(upload_dir)

    output:
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "UPLOAD_HIGLASS_DATA modules do not support Conda. Please use Docker / Singularity / Podman instead."
    }

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
    mkdir -p $upload_dir${higlass_data_basedir}/${species.replaceAll("\\s","_")}/${assembly}
    cp -f $mcool $upload_dir${higlass_data_basedir}/${species.replaceAll("\\s","_")}/${assembly}/${assembly}.mcool
    cp -f $genome $upload_dir/${higlass_data_basedir}/${species.replaceAll("\\s","_")}/${assembly}/${assembly}.genome

    # Load them in Kubernetes
    echo "Loading .mcool file"
    kubectl exec \$pod_name --  python /home/higlass/projects/higlass-server/manage.py ingest_tileset --filename /higlass-temp/${higlass_data_basedir}/${species.replaceAll("\\s","_")}/${assembly}/${assembly}.mcool --filetype cooler --datatype matrix --project-name ${higlass_data_basedir}/${species.replaceAll("\\s","_")}/$assembly --name ${assembly}_map
    echo "Loading .genome file"
    kubectl exec \$pod_name --  python /home/higlass/projects/higlass-server/manage.py ingest_tileset --filename /higlass-temp/${higlass_data_basedir}/${species.replaceAll("\\s","_")}/${assembly}/${assembly}.genome --filetype chromsizes.tsv --datatype chromsizes --coordSystem ${assembly}_assembly --project-name ${higlass_data_basedir}/${species.replaceAll("\\s","_")}/$assembly --name ${assembly}_grid
    echo "done"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kubectl: \$(kubectl version --output=json | jq -r ".clientVersion.gitVersion")
    END_VERSIONS
    """
}
