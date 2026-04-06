pipeline {
agent any

environment {
    AWS_DEFAULT_REGION = 'ap-south-1'
}

stages {

    stage('Checkout Code') {
        steps {
            git branch: 'main', url: 'https://github.com/shiubhole/cloud-monitoring-capstone.git'
        }
    }

    stage('Terraform Init') {
        steps {
            dir('terraform') {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-cred'
                ]]) {
                    sh 'terraform init'
                }
            }
        }
    }

    stage('Terraform Validate') {
        steps {
            dir('terraform') {
                sh 'terraform validate'
            }
        }
    }

    stage('Terraform Plan') {
        steps {
            dir('terraform') {
                sh 'terraform plan'
            }
        }
    }

    stage('Terraform Apply') {
        steps {
            dir('terraform') {
                sh 'terraform apply -auto-approve'
            }
        }
    }

}

post {
    success {
        echo 'Terraform Infrastructure Deployed Successfully'
    }
    failure {
        echo 'Terraform Deployment Failed'
    }
}


}
