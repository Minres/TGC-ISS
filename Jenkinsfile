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
        stage("build TGC-ISS"){
            steps {
                sh '''
                conan profile new --detect --force default
                cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DWITH_ASMJIT=OFF -DWITH_TCC=OFF -DWITH_LLVM=OFF
                cmake --build build -j
                '''
            }
        }
        stage("Checkout TGC-Compliance"){
            steps {
                checkout_project("https://git.minres.com/TGFS/TGC-COMPLIANCE.git", "master")
            }
        }
        stage("Test backends"){
            parallel {
                stage("Test interp") {
                    sh "mkdir interp"
                    sh "python3 run_act.py -core TGC5C -sim build/dbt-rise-tgc/tgc-sim -w interp --dockerless --backend interp"
                }
            }
        }
        
    }
}
