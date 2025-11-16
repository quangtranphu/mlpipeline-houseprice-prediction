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

#Get the cluster CA certificate
kubectl config view --raw --minify -o jsonpath='{.clusters[*].cluster.certificate-authority-data}' | base64 --decode > jenkins/ca.crt

# Create namespace model-serving
kubectl create ns model-serving

#Create a ServiceAccount for Jenkins
kubectl create sa jenkins -n model-serving

#Apply ClusterRoleBinding for the Jenkins SA
kubectl apply -f jenkins/jenkins-sa.yaml   # This file should bind the 'jenkins' SA to cluster-admin role

#Create a secret containing the SA token and CA certificate
kubectl create secret generic jenkins-sa-secret \
  --from-literal=token=$(kubectl create token jenkins -n model-serving) \
  --from-file=ca.crt=jenkins/ca.crt \
  -n model-serving

#Verify the token inside the secret
kubectl get secret jenkins-sa-secret -n model-serving -o jsonpath='{.data.token}' | base64 --decode

#Get the SA token to use directly in a .env file for Jenkins
kubectl create token jenkins -n model-serving  # Copy the output to K8S_SA_TOKEN

#Create a secret for the model API (MinIO credentials)
kubectl create secret generic model-api-secrets \
  --from-literal=MINIO_ACCESS_KEY=root \
  --from-literal=MINIO_SECRET_KEY=password \
  -n model-serving