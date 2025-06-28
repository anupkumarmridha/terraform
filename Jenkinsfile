pipeline {
    agent any
    environment {
        TF_WORKSPACE = "default"
    }
    options {
        skipDefaultCheckout(false)
        timestamps()
    }
    triggers {
        // Polling is optional; use webhooks for real-time
        // pollSCM(scmpoll_spec: '@hourly')
    }
    stages {
        stage('Terraform Init') {
            steps {
                script {
                    sh 'terraform init -input=false'
                }
            }
        }
        stage('Terraform Plan') {
            steps {
                script {
                    sh 'terraform plan -input=false -out=tfplan.out'
                }
            }
        }
        stage('Approval') {
            when {
                branch 'master'
            }
            steps {
                input message: 'Approve to apply Terraform changes to master?', ok: 'Apply'
            }
        }
        stage('Terraform Apply') {
            when {
                branch 'master'
            }
            steps {
                script {
                    sh 'terraform apply -input=false -auto-approve tfplan.out'
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
