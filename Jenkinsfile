// Define environment variables based on the branch name, build number, and other configurations
def ENV_NAME = getEnvName(env.BRANCH_NAME)
def CONTAINER_NAME = "calculator-"+ENV_NAME
def CONTAINER_TAG = getTag(env.BUILD_NUMBER, env.BRANCH_NAME)
def HTTP_PORT = getHTTPPort(env.BRANCH_NAME)
def EMAIL_RECIPIENTS = "hisamistolz@gmail.com"


node {
    try {
        stage('Initialize') {
             // Initialize Docker and Maven tools
            def dockerHome = tool 'DockerLatest'
            def mavenHome = tool 'MavenLatest'
            env.PATH = "${dockerHome}/bin:${mavenHome}/bin:${env.PATH}"
        }

        stage('Checkout') {
             // Checkout source code from the version control system
            checkout scm
        }

        stage('Build with test') {
          // Build the project and run tests using Maven
            sh "mvn clean install"
        }

        stage('Sonarqube Analysis') {
            // Perform SonarQube analysis for code quality
            withSonarQubeEnv('SonarQubeLocalServer') {
                sh " mvn sonar:sonar -Dintegration-tests.skip=true -Dmaven.test.failure.ignore=true"
            }
            // Wait for the quality gate result from SonarQube
            timeout(time: 1, unit: 'MINUTES') {
                def qg = waitForQualityGate() // Reuse taskId previously collected by withSonarQubeEnv
                if (qg.status != 'OK') {
                    error "Pipeline aborted due to quality gate failure: ${qg.status}"
                }
            }
        }

        stage("Image Prune") {
             // Clean up unused Docker images and stop the previous container
            imagePrune(CONTAINER_NAME)
        }

        stage('Image Build') {
            // Build a new Docker image
            imageBuild(CONTAINER_NAME, CONTAINER_TAG)
        }

        stage('Push to Docker Registry') {
             // Push the Docker image to Docker Hub
            withCredentials([usernamePassword(credentialsId: 'dockercredentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                pushToImage(CONTAINER_NAME, CONTAINER_TAG, USERNAME, PASSWORD)
            }
        }

        stage('Run App') {
            // Run the Docker container with the new image
            withCredentials([usernamePassword(credentialsId: 'dockercredentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                runApp(CONTAINER_NAME, CONTAINER_TAG, USERNAME, HTTP_PORT, ENV_NAME)

            }
        }

    } finally {
         // Clean up the workspace and send an email notification
        deleteDir()
        sendEmail(EMAIL_RECIPIENTS);
    }

}

// Helper function to prune Docker images and stop the container
def imagePrune(containerName) {
    try {
        sh "docker image prune -f"
        sh "docker stop $containerName"
    } catch (ignored) {
    }
}
// Helper function to build the Docker image
def imageBuild(containerName, tag) {
    sh "docker build -t $containerName:$tag  -t $containerName --pull --no-cache ."
    echo "Image build complete"
}

// Helper function to push the Docker image to Docker Hub
def pushToImage(containerName, tag, dockerUser, dockerPassword) {
    sh "docker login -u $dockerUser -p $dockerPassword"
    sh "docker tag $containerName:$tag $dockerUser/$containerName:$tag"
    sh "docker push $dockerUser/$containerName:$tag"
    echo "Image push complete"
}

// Helper function to run the Docker container
def runApp(containerName, tag, dockerHubUser, httpPort, envName) {
    sh "docker pull $dockerHubUser/$containerName"
    sh "docker run --rm --env SPRING_ACTIVE_PROFILES=$envName -d -p $httpPort:$httpPort --name $containerName $dockerHubUser/$containerName:$tag"
    echo "Application started on port: ${httpPort} (http)"
}

// Helper function to send an email notification
def sendEmail(recipients) {
    mail(
            to: recipients,
            subject: "Build ${env.BUILD_NUMBER} - ${currentBuild.currentResult} - (${currentBuild.fullDisplayName})",
            body: "Check console output at: ${env.BUILD_URL}/console" + "\n")
}

// Function to get the environment name based on the branch name
String getEnvName(String branchName) {
    if (branchName == 'master') {
        return 'prod'
    }
    return (branchName == 'develop') ? 'uat' : 'dev'
}
// Function to get the HTTP port based on the branch name
String getHTTPPort(String branchName) {
    if (branchName == 'master') {
        return '9001'
    }
    return (branchName == 'develop') ? '9002' : '8090'
}
// Function to get the Docker image tag based on the build number and branch name
String getTag(String buildNumber, String branchName) {
    if (branchName == 'main') {
        return buildNumber + '-unstable'
    }
    return buildNumber + '-stable'
}
