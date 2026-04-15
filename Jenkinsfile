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

    stage('Verify Files') {
        steps {
            sh 'ls -la'
        }
    }

    stage('Terraform Init') {
        steps {
            withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding',
                credentialsId: 'aws-cred'
            ]]) {
                sh 'terraform init'
            }
        }
    }

    stage('Terraform Validate') {
        steps {
            sh 'terraform validate'
        }
    }

    stage('Terraform Plan') {
        steps {
            sh  '''
            terraform plan \
            -var="alert_email=shivanibhole7@gmail.com" \
            -var="instances={web1={instance_type=\\"t3.micro\\"},web2={instance_type=\\"t3.micro\\"},jenkins-server={instance_type=\\"t3.small\\"},grafana-server={instance_type=\\"t3.micro\\"}}"
            '''
        }

    }

    stage('Terraform Apply') {
        steps {
            sh '''
            terraform apply -auto-approve \
            -var="alert_email=shivanibhole7@gmail.com" \
            -var="instances={web1={instance_type=\\"t3.micro\\"},web2={instance_type=\\"t3.micro\\"},jenkins-server={instance_type=\\"t3.small\\"},grafana-server={instance_type=\\"t3.micro\\"}}"
            '''
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
