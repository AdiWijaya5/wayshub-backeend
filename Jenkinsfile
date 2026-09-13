def secret = 'aws-ec2-ssh'          
def discordSecret = 'discord-webhook-url' 
def dockerHubSecret = 'dockerhub-creds'   
def server = 'jenkins@54.251.210.57' 
def directory = 'docker/wayshub-backend'         
def branch = 'main' 
def images = 'adiwijayajy/wayshub-backend:backend-stage' 
def container = 'wayshub-be'

pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    sendDiscordNotification(discordSecret, "🔄 **BACKEND CI/CD Started (STAGING)**\\nDetected new Backend update on branch **${branch}** (Build #${env.BUILD_NUMBER})", 3447003)
                }
            }
        }

        stage('Build Docker Image Backend') {
            steps {
                echo "Building Backend Docker Image: ${images}..."
                sh "docker build -t ${images} ."
            }
        }

        stage('Push Backend to Docker Hub') {
            steps {
                echo "Logging into Docker Hub and pushing backend image..."
                withCredentials([usernamePassword(credentialsId: dockerHubSecret, passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                    sh "docker push ${images}"
                }
                
                script {
                    sendDiscordNotification(discordSecret, '''📦 **Docker Hub Backend Update!** Image **''' + images + '''** successfully built and pushed to Docker Hub registry!''', 16753920)
                }
            }
        }

         stage('Deploy Backend & MySQL via Compose') {
            steps {
                echo "Deploying Backend and MySQL to server ${server} via Docker Compose..."
                sshagent(["${secret}"]) {
                    sh "ssh -o StrictHostKeyChecking=no ${server} 'mkdir -p ~/${directory}'"
                    sh "ssh -o StrictHostKeyChecking=no ${server} 'rm -f ~/${directory}/docker-compose.yaml'"
                    sh "scp -o StrictHostKeyChecking=no docker-compose.yaml ${server}:~/${directory}/docker-compose.yaml"
                    sh """
                    ssh -o StrictHostKeyChecking=no ${server} '
                        cd ~/${directory}
                        echo "MYSQL_ROOT_PASSWORD=rootpassword_anda" > .env
                        echo "MYSQL_DATABASE=wayshub_db" >> .env
                        echo "MYSQL_USER=wayshub_user" >> .env
                        echo "MYSQL_PASSWORD=userpassword_anda" >> .env
                        echo "DB_HOST=wayshub-db" >> .env
                        echo "DB_NAME=wayshub_db" >> .env
                        echo "DB_USER=wayshub_user" >> .env
                        echo "DB_PASSWORD=userpassword_anda" >> .env
                        echo "PORT=5000" >> .env
                        echo "NODE_ENV=production" >> .env
                    '
                    """
                    
                    sh "ssh -o StrictHostKeyChecking=no ${server} 'cd ~/${directory} && docker compose pull'"
                    sh "ssh -o StrictHostKeyChecking=no ${server} 'cd ~/${directory} && docker compose down || true'"
                    sh "ssh -o StrictHostKeyChecking=no ${server} 'cd ~/${directory} && docker compose up -d'"
                    sh "ssh -o StrictHostKeyChecking=no ${server} 'cd ~/${directory} && docker image prune -f'"
                }
            }
        }

        stage('Cleanup Workspace') {
            steps {
                echo "Cleaning up local build assets and workspace..."
                sh "docker rmi ${images} || true"
                cleanWs()
            }
        }
    }

    post {
        success {
            script {
                node {
                    try {
                        sendDiscordNotification(discordSecret, "✅ **BACKEND CI/CD Success (STAGING)!**\\nBackend and MySQL database successfully deployed via **Docker Compose**!\\nURL API: https://api.adiwijaya.studentdumbways.my.id", 3066993)
                    } catch (Exception e) {
                        echo "Gagal mengirim notifikasi sukses ke Discord: ${e.message}"
                    }
                }
            }
        }
        failure {
            script {
                node {
                    try {
                        sendDiscordNotification(discordSecret, "❌ **BACKEND CI/CD Failed (STAGING)!**\\nDeployment failed for Backend Build #${env.BUILD_NUMBER}. Silakan periksa halaman Console Log Jenkins.", 15158332)
                    } catch (Exception e) {
                        echo "Gagal mengirim notifikasi gagal ke Discord: ${e.message}"
                    }
                }
            }
        }
    }
}

def sendDiscordNotification(String credentialId, String text, int colorCode) {
    withCredentials([string(credentialsId: credentialId, variable: 'DISCORD_WEBHOOK')]) {
        def jsonPayload = "{\"embeds\": [{\"title\": \"Jenkins CI/CD Alert\", \"description\": \"${text}\", \"color\": ${colorCode}}]}"
        sh "curl -v -sS -H 'Content-Type: application/json' -X POST -d '${jsonPayload}' \$DISCORD_WEBHOOK"
    }
}
