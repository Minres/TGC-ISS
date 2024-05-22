void checkout_project(String repoUrl, String branch = 'develop') {
    checkout([
        $class: 'GitSCM',
        branches: [
            [name: "*/${branch}"]
        ],
        extensions: [
            [$class: 'CleanBeforeCheckout'],
            [$class: 'SubmoduleOption', disableSubmodules: false, parentCredentials: true, recursiveSubmodules: true, reference: '', trackingSubmodules: false]
        ],
        submoduleCfg: [],
        userRemoteConfigs: [
            [credentialsId: 'gitea-jenkins', url: repoUrl]
        ]
    ])
}



pipeline {
    agent {
        docker { 
                image 'git.minres.com/tooling/riscof_sail:latest'
            } 
    }

    stages {
        stage("Checkout Repositories"){
            steps {
                checkout_project("https://git.minres.com/TGFS/TGC-ISS.git")
                checkout_project("https://git.minres.com/TGFS/TGC-COMPLIANCE.git", "master")
            }
        }
        stage("Build TGC-ISS"){
            steps {
                sh 'pwd'
                sh 'ls -la'
                sh 'ls -la ..'
            }
        }
        
    }
}
