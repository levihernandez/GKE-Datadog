#!/bin/bash
# This script is built to run in GKE

nsp=${1}
apikey=${2}
declare -A arr
arr+=( ["Kernel"]="uname -r" ["Kubectl"]="kubectl version" ["Helm"]="helm version" ["Istio"]="istioctl version" ["OS"]="cat /etc/os-release" ["Istio-Injections"]="""kubectl get namespaces --show-labels""" ["Network-Policies"]="""kubectl get networkpolicies --all-namespaces""" )


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



> Install the Datadog values.yaml
helm install <deployment-version> -f values.yaml  datadog/datadog --set datadog.apiKey=${2} --set targetSystem=linux -n ${nsp}


> Get Datadog pods
kubectl get pods -n ${nsp} | cut -f1 -d\" \" | grep -v \"NAME\"


> Get the Datadog cluster agent pod
kubectl get pods -n ${nsp} | cut -f1 -d\" \" | grep -v \"NAME\" | grep \"datadog-cluster-agent\"


> Get the Datadog cluster agent status
kubectl exec -it <datadog-cluster-agent pod> datadog-cluster-agent status -n ${nsp}


> To send files to support, open a case first and get the <CASE_ID> (numeric value), run a flare collection
kubectl exec <datadog-cluster-agent pod> -it datadog-cluster-agent flare <CASE_ID>


> To reset, clean up everything for the Datadog namespace (please validate that the following will not damage your configs, cluster, system)
kubectl delete replicasets,subscriptions,deployments,jobs,services,pods --all -n ${nsp}


> Identify the daemonsets that respawn Pods
kubectl describe pod <pod name> -n ${nsp} | grep 'Controlled By:'


> Delete (at your discretion) the daemonset deployment versions
kubectl delete daemonset <kubectl delete daemonset datadog-version -n ${nsp}
"""

