pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                script {
                    dockerImage = docker.build("lstar974/serveur")
                }
            }
        }
        stage('Push image') {
      steps {
        script {
          withDockerRegistry(credentialsId: 'docker') {
            dockerImage.push()
          }
        }
      }
    }
        stage('Create environment') {
            steps {
                ansiblePlaybook credentialsId: 'ssh', inventory: 'hosts.yml', playbook: 'playbook.yml'
            }
        }
        stage('Deploy') {
            steps {
                ansiblePlaybook credentialsId: 'ssh', inventory: 'hosts.yml', playbook: 'deploy.yml'
            }
        }
    }
}
