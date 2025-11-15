pipeline {
    agent any

    options{
        // Max number of build logs to keep and days to keep
        buildDiscarder(logRotator(numToKeepStr: '5', daysToKeepStr: '5'))
        // Enable timestamp at each job in the pipeline
        timestamps()
    }

    environment{
        registry = 'quangtp/house-price-prediction-api'
        registryCredential = 'dockerhub'
        nameSpace = 'model-serving'
        helmChartPath = './helm-charts/hpp'   
        releaseName='hpp'
        pullPolicy = 'Always'
        context='gke_inner-replica-469607-h9_europe-west3-a_inner-replica-469607-h9-new-gke'
        K8S_CLOUD_NAME='quangtp-cluster-1'
        K8S_AGENT_LABEL='k8s-agent'
    }

    stages {
        // stage('Test') {
        //     agent {
        //         docker {
        //             image 'python:3.8-slim' 
        //             args '-u root:root' //run image with root
        //         }
        //     }
        //     steps {
        //         echo 'Testing model correctness..'
        //         sh 'pip install -r requirements.txt'
        //     }
        // }
        stage('Build docker image') {
            steps {
                script {
                    echo 'Building image for deployment..'
                    dockerImage = docker.build registry + ":$BUILD_NUMBER" 
                    echo 'Pushing image to dockerhub..'
                    docker.withRegistry( '', registryCredential ) {
                        dockerImage.push() // Push tag build-number
                        dockerImage.push('latest') // Push tag latest
                    }
                }
            }
        }
        stage('Deploy to K8s') {
            agent {
                kubernetes {
                    cloud "${K8S_CLOUD_NAME}" // Tên cloud Kubernetes trong Jenkins
                    serviceAccount 'jenkins' 
                    containerTemplate {
                        name 'helm'                          // Container name
                        image 'quangtp/custom-jenkins:latest' // Image chứa helm + kubectl
                        command 'cat'                        // Giữ container chạy
                        ttyEnabled true
                        alwaysPullImage false                // Pull only if not present
                    }
                }
            }
            steps {
                container('helm') {
                    script {
                        // Upgrade/install Helm release
                        sh """
                            helm upgrade --install ${releaseName} ${helmChartPath} \
                                --namespace ${nameSpace} \
                                --set image.repository=${registry} \
                                --set image.tag=${BUILD_NUMBER} \
                                --set image.pullPolicy=${pullPolicy}
                                
                        """
                        sh "kubectl rollout restart deployment ${releaseName} -n ${namespace}"
                    }
                }
            }
        }

        stage('Clean up'){
            steps {
                script {
                    echo 'Delete local image hehe'
                    sh 'docker rmi ${registry}:${BUILD_NUMBER} ${registry}:latest || true'
                }
            }
        }
    }
}