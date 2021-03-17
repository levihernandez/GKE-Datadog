#!/bin/bash
# This script is built to run in GKE

nsp=${1}
apikey=${2}
declare -A arr
kb="kubectl"

# Declare commands to execute and collect information from the cluster
# Syntax: ["<key-name>"]="basic command"
arr+=( ["Kernel"]="uname -r" ["${kb}"]="${kb} version" ["Helm"]="helm version" ["Istio"]="istioctl version" ["OS"]="cat /etc/os-release" ["Istio-Injections"]="""${kb} get namespaces --show-labels""" ["Network-Policies"]="""${kb} get networkpolicies --all-namespaces""" ["Get-Deployments"]="""${kb} get deployments""" ["Get-DD-Deployment"]="""${kb} get deployments -n ${nsp}""" ["Get-DD-Pod-Info"]="""${kb} get pods -n ${nsp} -o custom-columns=NAME:metadata.name,HOST_IP:status.hostIP,POD_IP:status.podIP,PHASE:status.phase""")
for key in ${!arr[@]}; do
    echo  "======================================"
    echo  "GET ${key} info: '${arr[${key}]}'"
    echo  "======================================"
    printf "%s$(${arr[${key}]})"
    echo ""
    echo ""
done



echo """
Common commands used during the implementation of Datadog K8s

------------------------------------------------------------------
WARNING: The following commands are reference points, please use
discretion when running deletions.
In some instances, removing the deployments first creates
conflicts re-using the deployment versions when using helm install.
If you proceed with the usage of the commands below, you agree that
you understand their functionality:
------------------------------------------------------------------

> Create Datadog namespace:
    kubectl create namespace ${nsp}


> Get the Datadog Helm Repo
    helm repo add datadog https://helm.datadoghq.com
    helm repo update

"""

ddclagent=$(kubectl get pods -n ${nsp} -o custom-columns=NAME:metadata.name --no-headers=true | grep \"datadog-cluster-agent\")
if [[ ${ddclagent} ]]; then
    echo """> Cluster Agent exists:     
    ${ddclagent}"""
else
    ddclagent="<datadog-cluster-agent pod>"
    echo """> Get the Datadog cluster agent pod
    kubectl get pods -n ${nsp} -o custom-columns=NAME:metadata.name --no-headers=true | grep \"datadog-cluster-agent\""""

fi

echo """

> Install the Datadog values.yaml
    helm install <deployment-version> -f values.yaml  datadog/datadog --set datadog.apiKey=${2} --set targetSystem=linux -n ${nsp}

> Get Deployments in Datadog namespace
    kubectl get deployments -n ${nsp}

> Get Datadog pods
    kubectl get pods -n ${nsp} -o custom-columns=NAME:metadata.name --no-headers=true


> Get the *datadog-cluster-agent* pod name
    kubectl get pods -n ${nsp} -o custom-columns=NAME:metadata.name --no-headers=true | grep \"datadog-cluster-agent\"


> Get the Datadog cluster agent status
    kubectl exec -it <datadog-cluster-agent pod> datadog-cluster-agent status -n ${nsp}


> To send files to support, open a case first and get the <CASE_ID> (numeric value), run a flare collection
kubectl exec <datadog-cluster-agent pod> -it datadog-cluster-agent flare <CASE_ID>


> To reset, clean up everything for the Datadog namespace (please validate that the following will not damage your configs, cluster, system)
kubectl delete replicasets,subscriptions,deployments,jobs,services,pods --all -n ${nsp}

"""

declare arr2
arr2=$(${kb} get pods -n ${nsp} -o custom-columns=NAME:metadata.name --no-headers=true)

echo "> Identify the daemonsets that respawn Pods"
if [[ ${arr2} ]]; then
    for i in ${arr2[@]}; do
        echo "    kubectl describe pod ${i} -n ${nsp} | grep 'Controlled By:'"
    done

else
    echo "    kubectl describe pod <pod name> -n ${nsp} | grep 'Controlled By:'"
fi


echo """
> Delete (at your discretion) the daemonset deployment versions
    kubectl delete daemonset <kubectl delete daemonset datadog-version -n datadog> -n ${nsp}
"""

