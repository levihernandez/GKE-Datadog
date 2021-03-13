# GKE-Datadog
Test Datadog integration with GKE Istio

## Execution

* Get the script in GKE terminal
```bash
git clone https://github.com/levihernandez/GKE-Datadog
cd GKE-Datadog
chmod +x getK8sInfo.sh
cd ../
./GKE-Datadog/getK8sInfo.sh "datadog" "1111111111111111"
```
* Run the script with the namespace of `datadog` (optional) and Datadog APKI Key (optional)

```bash
SYNTAX: ./getK8sInfo.sh <namespace> "<dd-api-key>"
```
* The script will collect the basic data from the K8s cluster as shown in the sample output [gke-getInfo.txt](gke-getInfo.txt)

## Helm Install Datadog + Istio Integration

`helm install <deployment-version> -f istio-dd-values.yaml  datadog/datadog --set datadog.apiKey=<dd-api-key> --set targetSystem=linux -n datadog`
