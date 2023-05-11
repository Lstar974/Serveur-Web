pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t servweb .'
            }
        }
        stage('Deploy') {
            steps {
                sh 'docker run -d -p 80:80 -p 443:443 servweb'
            }
        }
    }
}
