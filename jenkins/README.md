This tutorial shows how to deploy a simple house price prediction model.

## How-to Guide

### Start Jenkins service locally
```shell
docker compose -f docker-compose.yaml up -d
```
You can find the password for `admin` at the path `/var/jenkins_home/secrets/initialAdminPassword` in the container Jenkins.

### Push the whole code to Github for automatic deployment
```shell
git add --all
git commit -m "first attempt to deploy the model"
git push origin your_branch

# Connect to GKE
gcloud container clusters get-credentials inner-replica-469607-h9-new-gke --zone europe-west3-a --project inner-replica-469607-h9

kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode > ca.crt

kubectl create secret generic jenkins-sa-secret \
  --from-literal=token=$(kubectl create token jenkins -n model-serving) \
  --from-file=ca.crt=ca.crt \
  -n model-serving

kubectl get secret jenkins-sa-secret -n model-serving -o jsonpath='{.data.token}' | base64 --decode

# kubectl create secret generic jenkins-token   --from-literal=token=$(openssl rand -hex 16)   -n model-serving
```