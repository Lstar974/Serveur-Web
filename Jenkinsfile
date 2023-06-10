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
        stage('Deploy environment') {
            steps {
                ansiblePlaybook credentialsId: 'ssh', inventory: 'hosts.yml', playbook: 'playbook.yml'
            }
        }
        stage('Run Selenium tests') {
      steps {
        sh '/usr/bin/python3 /var/lib/jenkins/workspace/DevOps/test_selenium.py'
            }
        }
    }
    post {
        success {
            mail to: 'lucas.buchle@gmail.com',
            subject: "Build succeeded in Jenkins",
            body: '''<html>
                     <p>Hello,</p>
                     <p>The build DevOps has succeeded.</p>
                     <p>Check console output at <a href="${env.BUILD_URL}">${env.JOB_NAME}#${env.BUILD_NUMBER}</a></p>
                     </html>''',
            mimeType: 'text/html'
        }
        failure {
            mail to: 'lucas.buchle@gmail.com',
            subject: "Build failed in Jenkins",
            body: '''<html>
                     <p>Hello,</p>
                     <p>The build DevOps has failed.</p>
                     <p>Check console output at <a href="${env.BUILD_URL}">${env.JOB_NAME}#${env.BUILD_NUMBER}</a></p>
                     </html>''',
            mimeType: 'text/html'
        }
    }
}
