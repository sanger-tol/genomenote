process UPDATE_HIGLASS_SERVER {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::coreutils=9.1"
    container "bitnami/kubectl:1.27"

    input:
    tuple val(meta), path(mcool)
    tuple val(meta), path(genome)
    val(assembly)

    output:
    tuple val(meta), path(mcool)
    tuple val(meta), path(genome)

    when:
    task.ext.when == null || task.ext.when

    script:

    """
    export KUBECONFIG=$params.higlass_kubeconfig
    kubectl config get-contexts
    kubectl config set-context --current --namespace=$params.higlass_namespace

    sel=\$(kubectl get deployments.apps $params.higlass_deployment_name --output=json | jq -j '.spec.selector.matchLabels | to_entries | .[] | "\\(.key)=\\(.value),"')
    sel2=\${sel%?}
    pod_name=\$(kubectl get pod --selector=\$sel2 --output=jsonpath={.items[0].metadata.name})
    echo "\$pod_name"
    echo "Loading .mcool file"
    kubectl exec \$pod_name --  python /home/higlass/projects/higlass-server/manage.py ingest_tileset --filename /higlass-temp/$mcool.name --filetype cooler --datatype matrix --project-name $assembly --name ${assembly}_map
    echo "Loading .genome file"
    kubectl exec \$pod_name --  python /home/higlass/projects/higlass-server/manage.py ingest_tileset --filename /higlass-temp/${genome.baseName}.genome --filetype chromsizes.tsv --datatype chromsizes --coordSystem ${assembly}_assembly --project-name $params.assembly --name ${assembly}_grid
    echo "done"
    """
}
