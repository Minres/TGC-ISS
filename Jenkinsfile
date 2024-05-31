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
                args ' -e CONAN_USER_HOME=/var/jenkins_home/workspace/riscof_sail'
            } 
    }
    stages {
        stage("Checkout TGC-ISS"){
            steps {
                checkout_project("https://git.minres.com/TGFS/TGC-ISS.git", "develop")
            }
        }
        stage("build TGC-ISS"){
            steps {
                sh 'conan profile new default --detect --force '
                sh 'cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DWITH_ASMJIT=ON -DWITH_TCC=ON -DWITH_LLVM=ON'
                sh 'cmake --build build -j'
            }
        }
        stage("Checkout TGC-Compliance"){
            steps {
                dir("TGC-COMPLIANCE"){
                    checkout_project("https://git.minres.com/TGFS/TGC-COMPLIANCE.git", "master")
                }
            }
        }
        stage("Test backends"){
            parallel {
                stage("Test interp") {
                    steps {
                        sh "mkdir interp"
                        sh "python3 TGC-COMPLIANCE/run_act.py -core TGC5C -sim build/dbt-rise-tgc/tgc-sim -w interp --dockerless --backend interp"
                    }
                }
                stage("Test tcc") {
                    steps {
                        sh "mkdir tcc"
                        sh "python3 TGC-COMPLIANCE/run_act.py -core TGC5C -sim build/dbt-rise-tgc/tgc-sim -w tcc --dockerless --backend tcc"
                    }
                }
                stage("Test asmjit") {
                    steps {
                        sh "mkdir asmjit"
                        sh "python3 TGC-COMPLIANCE/run_act.py -core TGC5C -sim build/dbt-rise-tgc/tgc-sim -w asmjit --dockerless --backend asmjit"
                    }
                }
                stage("Test llvm") {
                    steps {
                        sh "mkdir llvm"
                        sh "python3 TGC-COMPLIANCE/run_act.py -core TGC5C -sim build/dbt-rise-tgc/tgc-sim -w llvm --dockerless --backend llvm"
                    }
                }
            }
        } 
    }
}
