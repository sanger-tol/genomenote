process UPDATE_HIGLASS_SERVER {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::coreutils=9.1"
    container "bitnami/kubectl:1.27"

    input:
    tuple val(meta), path(mcool)
    tuple val(meta2), path(genome)
    val(assembly)
    path(upload_dir)

    output:
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

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
    cp -f $mcool $upload_dir
    cp -f $genome $upload_dir/${genome.baseName}.genome

    # Load them in Kubernetes
    echo "Loading .mcool file"
    kubectl exec \$pod_name --  python /home/higlass/projects/higlass-server/manage.py ingest_tileset --filename /higlass-temp/$mcool.name --filetype cooler --datatype matrix --project-name $assembly --name ${assembly}_map
    echo "Loading .genome file"
    kubectl exec \$pod_name --  python /home/higlass/projects/higlass-server/manage.py ingest_tileset --filename /higlass-temp/${genome.baseName}.genome --filetype chromsizes.tsv --datatype chromsizes --coordSystem ${assembly}_assembly --project-name $params.assembly --name ${assembly}_grid
    echo "done"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kubectl: \$(kubectl version --output=json | jq -r ".clientVersion.gitVersion")
    END_VERSIONS
    """
}
