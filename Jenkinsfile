pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                dockerImage = docker.build("lstar974/hebergement")
            }
        }
        stage('Create environment') {
            steps {
                ansiblePlaybook credentialsId: 'ssh', inventory: 'hosts.yml', playbook: 'playbook.yml'
            }
        }
        stage('Deploy') {
            steps {
                sh 'docker run -d -p 80:80 -p 443:443 servweb'
            }
        }
    }
}
