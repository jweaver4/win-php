#!/usr/bin/env groovy

node (label: 'win-agent-1') {
    def app
  /*  EMAIL_TO = 'jay.weaver@usda.gov'
  try { */
      stage('Clone repository') {
          /* Let's make sure we have the repository cloned to our workspace */
          checkout scm
      }

      stage('Build image') {
        /* This builds the actual image; synonymous to
        * docker build on the command line */
        app = docker.build("pe-201642-agent.puppetdebug.vlan:5000/windows/win_php:${env.BUILD_NUMBER}", '--no-cache --pull .')
      }

      stage('Test image') {
          /* Ideally, we would run a test framework against our image.
          * For this example, we're using a Volkswagen-type approach ;-) */
        withSonarQubeEnv('sonarqube') {
          bat "C:/sonarscanner-msbuild/sonar-scanner-3.3.0.1492/bin/sonar-scanner.bat"
        }
        timeout(time: 10, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }

      stage('Push image to DTR') {
      /* Finally, we'll push the image with two tags:
        * First, the incremental build number from Jenkins
        * Second, the 'latest' tag.
        * Pushing multiple tags is cheap, as all the layers are reused. */
        docker.withRegistry('http://pe-201642-agent.puppetdebug.vlan:5000', 'portus_registry') {
          app.push("${env.BUILD_NUMBER}")
        }
      }

      stage('Remove existing container') {
        sh 'docker ps -f name=php -q | xargs --no-run-if-empty docker container stop'
        sh 'docker container ls -a -fname=php -q | xargs -r docker container rm'
      }

      stage('Deploy new container') {
        docker.image("pe-201642-agent.puppetdebug.vlan:5000/windows/win_php:${env.BUILD_NUMBER}").run("--name php -p 8081:80")
      }

      stage('Prune Docker Images') {
        bat 'docker system prune -f'
      }

    currentBuild.result = 'SUCCESS'
  /*}
  catch (err) {
    currentBuild.result = 'FAILURE'
  }
  finally {
    mail to: EMAIL_TO,
         from: 'jenkins.fs@usda.gov',
         subject: "Status of pipeline: ${currentBuild.fullDisplayName}",
         body: "${env.BUILD_URL} has result ${currentBuild.result}"
  } */

}
