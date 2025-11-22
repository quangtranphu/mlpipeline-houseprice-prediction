This tutorial shows how to deploy a simple house price prediction model.

## How-to Guide

### Start Jenkins service locally
```shell
docker compose -f jenkins/docker-compose.yaml up -d
```
You can find the password for `admin` at the path `/var/jenkins_home/secrets/initialAdminPassword` in the container Jenkins.

### Start your cloud infrastructure
```shell
cd iac/terraform_aws/ 
or cd iac/terraform_gcp/
terraform init
terraform plan
terraform apply
```

### Connect to cluster
```shell
#GCP
gcloud container clusters get-credentials inner-replica-469607-h9-new-gke --zone europe-west3-a --project inner-replica-469607-h9

#AWS
aws eks update-kubeconfig --region region-code --name my-cluster

#Verify cluster connection
kubectl get nodes
```
#### Create service account for cluster
```shell
#Get the cluster CA certificate
kubectl config view --raw --minify -o jsonpath='{.clusters[*].cluster.certificate-authority-data}' | base64 --decode > jenkins/ca.crt

#Create namespace model-serving
kubectl create ns model-serving

#(Optional) Switch to model-serving namespace
kubens model-serving

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
kubectl create token jenkins -n model-serving  # Copy output to K8S_SA_TOKEN

#Create a secret for the model API (MinIO credentials)
kubectl create secret generic model-api-secrets \
  --from-literal=MINIO_ACCESS_KEY=root \
  --from-literal=MINIO_SECRET_KEY=password \
  -n model-serving
```
### Create MinIO to host model
```shell
kubectl apply -f minio-k8s/
```

### Helm charts

#### For model API
```shell
cd helm-charts/hpp/
helm upgrade --install hpp .
```

#### For monitoring tools
```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack
### Install chart with fixed version
helm install prometheus prometheus-community/kube-prometheus-stack --version "9.4.1"
```

### Push the whole code to Github for automatic deployment
```shell
git add --all
git commit -m "first attempt to deploy the model"
git push origin your_branch