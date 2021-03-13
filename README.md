# GKE-Datadog
Test Datadog integration with GKE Istio

## Execution

* Run the script with the namespace of `datadog` (optional) and Datadog APKI Key (optional)

```bash
SYNTAX: ./getK8sInfo.sh <namespace> "<dd-api-key>"

EXAMPLE: getK8sInfo.sh "datadog" "1111111111111111"
```
* The script will collect the basic data from the K8s cluster as shown in the sample output [gke-getInfo.txt](gke-getInfo.txt)
