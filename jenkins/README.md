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

### Example .env file
```shell
jenkins_admin_user=
jenkins_admin_pwd=
jenkins_user=
jenkins_pwd=

JENKINS_URL= #change this link if re-created

DOCKER_USER=
DOCKER_PASSWORD=

GIT_USER=
GIT_PASSWORD= #access token

# Kubernetes cluster credentials
# -------------------------------
K8S_CRED_ID=            # Jenkins credential ID for K8s cluster
K8S_SERVER_URL=  # Kubernetes API server URL - change this if change cluster
K8S_NAMESPACE=             # Namespace containing the Jenkins Service Account
K8S_SECRET=

#change k8s SA token if new cluster created
K8S_SA_TOKEN=
K8S_SERVICE_ACCOUNT=

# -------------------------------
# Jenkins Kubernetes agent
# -------------------------------
K8S_CLOUD_NAME=              # Name of the Kubernetes Cloud in Jenkins JCasC
K8S_AGENT_LABEL=               # Label used in pipeline for the agent pod
K8S_AGENT_IMAGE=  # Image of the Jenkins agent (kubectl + helm)
```