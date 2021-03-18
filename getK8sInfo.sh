#!/bin/bash
# This script is built to run in GKE

nsp=${1}
apikey=${2}
declare -A arr
kb="kubectl"

# Declare commands to execute and collect information from the cluster
# Syntax: ["<key-name>"]="basic command"
arr+=( ["Kernel"]="uname -r" ["${kb}"]="${kb} version" ["Helm"]="helm version" ["Istio"]="istioctl version" 
["OS"]="cat /etc/os-release" ["Istio-Injections"]="""${kb} get namespaces --show-labels""" 
["Network-Policies"]="""${kb} get networkpolicies --all-namespaces""" ["Get-Deployments"]="""${kb} get deployments""" 
["Get-DD-Deployment"]="""${kb} get deployments -n ${nsp}""" 
["Get-DD-Pod-Info"]="""${kb} get pods -n ${nsp} -o custom-columns=NAME:metadata.name,HOST_IP:status.hostIP,POD_IP:status.podIP,PHASE:status.phase""" 
["Helm-Charts-Versions"]="""helm list -n ${nsp}""" ["Istio-Proxy-Status"]="""istioctl proxy-status""" )
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

declare -A arr3
arr3=$(kubectl get pods -n ${nsp} -o custom-columns=NAME:metadata.name --no-headers=true | grep "datadog-cluster-agent")

if [[ ${arr3} ]]; then
    echo "> Cluster Agent exists: "
    for i in ${arr3[@]}; do
        echo "    ${i}"
    done
    echo " "
    echo "> Selecting the latest Datadog deployment"
    ddclagent=${i}
    echo "    ${ddclagent}"
else
    ddclagent="<datadog-cluster-agent pod>"
fi

echo """
> Get the Datadog cluster agent pod
    kubectl get pods -n ${nsp} -o custom-columns=NAME:metadata.name --no-headers=true | grep \"datadog-cluster-agent\"
    
> Get deployments
    kubectl get deployments -n ${nsp} -o custom-columns=NAME:metadata.name --no-headers=true | grep \"datadog\"
"""

declare -A arr4
arr4=$(kubectl get deployments -n ${nsp} -o custom-columns=NAME:metadata.name --no-headers=true | grep "datadog")

if [[ ${arr4} ]]; then
    echo "> Deployment(s) found: "
    for i in ${arr4[@]}; do
        echo "    ${i}"
    done
    echo " "
    echo "> Selecting the latest Datadog deployment"
    dddplym=${i}
    echo "    ${dddplym}"
else
    dddplym="<datadog-cluster-agent pod>"
fi

declare arr5
arr5=$(helm list -n datadog | grep -v "NAME" | awk '{print $1}')
if [[ ${arr5} ]]; then
    for i in ${arr5[@]}; do
        hemlrls=${i}
    done

else
    hemlrls="<NAME>"
fi

echo """
> Get deployment
    kubectl get deployment ${dddplym}  -n datadog -o custom-columns=NAME:metadata.name --no-headers=true

> Install the Datadog values.yaml and create the <helm-release-name> in the same statement
    helm install <helm-release-name> -f values.yaml  datadog/datadog --set datadog.apiKey=${2} --set targetSystem=linux -n ${nsp} --set version=1.0.0

    

> Update changes to Datadog values.yaml
    helm upgrade --cleanup-on-fail <helm-release-name> datadog/datadog --version=<chart-version> -f values.yaml -n ${nsp} --version=1.1.0

    helm install dd1 -f values.yaml  datadog/datadog --set datadog.apiKey=1232 --set targetSystem=linux -n datadog 
    helm upgrade --cleanup-on-fail dd1 datadog/datadog -f values.yaml -n datadog 

> Install the Manifest app_daemonset.yaml
    kubectl apply -f sample-node-app.yaml

> Verify status of app Rollout 
    kubectl rollout status deployment/nodejs

> Get Deployments in Datadog namespace
    kubectl get deployments -n ${nsp}

> Get Datadog pods
    kubectl get pods -n ${nsp} -o custom-columns=NAME:metadata.name --no-headers=true


> Get the *datadog-cluster-agent* pod name
    kubectl get pods -n ${nsp} -o custom-columns=NAME:metadata.name --no-headers=true | grep \"datadog-cluster-agent\"


> Get the Datadog cluster agent status
    kubectl exec -it ${ddclagent} datadog-cluster-agent status -n ${nsp}


> To send files to support, open a case first and get the <CASE_ID> (numeric value), run a flare collection
    kubectl exec ${ddclagent} -it datadog-cluster-agent flare <CASE_ID>


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
> Clean up all datadog resources from a Deployment created by Helm
    helm list -n ${nsp}

> Uninstall helm deployment
    helm uninstall ${hemlrls} -n ${nsp}

> Delete (at your discretion) the daemonset deployment versions
    kubectl delete daemonset datadog-version -n ${nsp}
"""

